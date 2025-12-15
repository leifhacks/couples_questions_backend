# frozen_string_literal: true

module Api
  module V1
    class AuthController < GenericController
      def initialize
        super(Validate::Auth::Bootstrap, Base64Decoder.new)
      end

      skip_before_action :validate_with_validator
      before_action -> { validate_with_validator(Validate::Auth::Bootstrap) }, only: [:bootstrap]
      before_action -> { validate_with_validator(Validate::Auth::Refresh) }, only: [:refresh]
      before_action -> { validate_with_validator(Validate::Auth::Invalidate) }, only: [:invalidate]
      # POST /api/v1/auth/bootstrap
      def bootstrap
        ActiveRecord::Base.transaction do
          user = create_user!

          relationship, invite_code = relationship_bootstrap_service.create_for_user!(
            user: user,
            timezone_name: device_params[:timezone_name],
            timezone_offset_seconds: device_params[:timezone_offset_seconds]
          )

          device = user.client_devices.create!(
            device_token: device_params[:device_token],
            platform: device_params[:platform],
            iso_code: device_params[:iso_code],
            timezone_name: device_params[:timezone_name],
            timezone_offset_seconds: device_params[:timezone_offset_seconds]
          )

          # Store 20:00 in the user's local time as UTC hours/minutes
          offset_seconds = device_params[:timezone_offset_seconds].to_i
          local_seconds = 20 * 3600 # 20:00 in seconds
          utc_seconds = (local_seconds - offset_seconds) % (24 * 3600)
          utc_hours = utc_seconds / 3600
          utc_minutes = (utc_seconds % 3600) / 60

          PushNotification.notification_types.each_key do |notification_type|
            user.push_notifications.create!(
              notification_type: notification_type,
              hours: utc_hours,
              minutes: utc_minutes
            )
          end

          refresh_token = token_service.generate_refresh_token
          UserSession.create!(
            user: user,
            refresh_token_hash: token_service.hash_refresh_token(refresh_token),
            expires_at: token_service.refresh_expires_at,
            active: true
          )

          access_token = token_service.issue_access_token(user)

          render json: bootstrap_response(user, device, relationship, invite_code, access_token, refresh_token), status: :created
        end
      end

      # POST /api/v1/auth/refresh
      def refresh
        refresh_token = params.require(:refresh_token)
        session = find_active_session(refresh_token)
        return render json: { error: 'invalid_refresh_token' }, status: :unauthorized if session.nil?
        user = session.user
        access_token = token_service.issue_access_token(user)
        render json: token_payload(access_token, refresh_token)
      end

      # POST /api/v1/auth/invalidate
      def invalidate
        token = params.require(:refresh_token)
        session = find_active_session(token)
        return render json: { error: 'invalid_refresh_token' }, status: :unauthorized if session.nil?

        user = session.user
        user.destroy!
        render json: { status: 'ok' }
      end

      private

      def token_service
        @token_service ||= TokenService.new(refresh_token_ttl: 10 * 365 * 24 * 60 * 60) # 10 years
      end

      def relationship_bootstrap_service
        @relationship_bootstrap_service ||= RelationshipBootstrapService.new
      end

      def create_user!
        User.create!(name: '')
      end

      def bootstrap_response(user, device, relationship, invite_code, access_token, refresh_token)
        token_payload(access_token, refresh_token).merge(
          user: user.payload,
          device: device.payload,
          relationship: relationship.payload.merge(invite_code: invite_code.payload)
        )
      end

      def token_payload(access_token, refresh_token)
        {
          access_token: access_token,
          refresh_token: refresh_token,
          token_type: 'Bearer',
          access_token_expires_in: token_service.access_token_ttl,
          refresh_token_expires_at: UserSession.find_by(refresh_token_hash: token_service.hash_refresh_token(refresh_token), active: true)&.expires_at
        }
      end

      def bootstrap_params
        params.permit(
          device: %i[device_token platform iso_code timezone_name timezone_offset_seconds]
        )
      end

      def device_params
        dev = bootstrap_params[:device] || {}
        # Also support top-level fallbacks if client does not nest under device
        {
          device_token: dev[:device_token] || params[:device_token],
          platform: dev[:platform] || params[:platform],
          iso_code: dev[:iso_code] || params[:iso_code],
          timezone_name: dev[:timezone_name] || params[:timezone_name],
          timezone_offset_seconds: dev[:timezone_offset_seconds] || params[:timezone_offset_seconds]
        }.with_indifferent_access
      end

      def find_active_session(refresh_token)
        hash = token_service.hash_refresh_token(refresh_token)
        session = UserSession.find_by(refresh_token_hash: hash, active: true)
        return nil if session.nil? || session.expires_at <= Time.current
        session
      end
    end
  end
end


