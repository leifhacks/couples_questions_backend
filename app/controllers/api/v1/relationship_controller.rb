# frozen_string_literal: true

module Api
  module V1
    class RelationshipController < GenericController
      include ::UserAuthentication

      def initialize
        super(Validate::Relationship::Update, Base64Decoder.new)
      end

      before_action :authenticate_user!
      skip_before_action :validate_data, :decode_params, only: [:show]
      before_action :ensure_active_or_pending_relationship!, only: [:show, :update, :new_invite]
      before_action -> { validate_with_validator(Validate::Relationship::Update) }, only: [:update]
      before_action -> { validate_with_validator(Validate::Relationship::ConfirmInvite) }, only: [:confirm_invite]
      before_action -> { validate_with_validator(Validate::Relationship::RedeemInvite) }, only: [:redeem_invite]

      # GET /api/v1/relationship
      def show
        relationship = current_user.current_relationship
        render json: relationship_payload(relationship)
      end

      # POST /api/v1/relationship
      def update
        relationship = current_user.current_relationship
        relationship.update!(update_params) unless update_params.empty?
        render json: relationship_payload(relationship)
      end

      # GET /api/v1/relationship/new_invite
      def new_invite
        relationship = current_user.current_relationship
        return render(json: { error: 'invalid_status' }, status: :bad_request) if relationship.ACTIVE?

        invite = invite_code_service.issue!(relationship: relationship, created_by_user: current_user)
        render json: { invite_code: { code: invite.code, expires_at: invite.expires_at } }
      end

      # POST /api/v1/relationship/unpair
      def unpair
        relationship = current_user.current_relationship
        return render(json: { error: 'invalid_status' }, status: :bad_request) unless relationship&.ACTIVE?

        ActiveRecord::Base.transaction do
          relationship.update!(status: 'ENDED')
          relationship.relationship_memberships.includes(:user).find_each do |m|
            m.user.update!(current_relationship_id: nil)
          end
          # Optionally remove memberships entirely after unpair
          relationship.relationship_memberships.destroy_all
        end

        render json: { status: 'ok' }
      end

      # POST /api/v1/relationship/confirm_invite
      def confirm_invite
        relationship = current_user.current_relationship
        return render(json: { error: 'invalid_status' }, status: :bad_request) unless relationship&.PENDING?

        membership = RelationshipMembership.find_by(relationship: relationship, user: current_user)
        return render(json: { error: 'forbidden' }, status: :forbidden) unless membership&.OWNER?

        partner = relationship.users.find_by(uuid: params[:partner_uuid])
        return render(json: { error: 'partner_not_found' }, status: :not_found) if partner.nil?

        case params[:action_type]
        when 'APPROVE'
          relationship.update!(status: 'ACTIVE')
          render json: relationship_payload(relationship)
        when 'REJECT'
          RelationshipMembership.where(relationship: relationship, user: partner).destroy_all
          partner.update!(current_relationship_id: nil)
          render json: relationship_payload(relationship)
        else
          render json: { error: 'invalid_action' }, status: :bad_request
        end
      end

      # POST /api/v1/relationship/redeem_invite
      def redeem_invite
        code = InviteCode.find_by(code: params[:invite_code])
        return render(json: { error: 'invalid_code' }, status: :not_found) if code.nil?
        return render(json: { error: 'expired' }, status: :bad_request) if code.expires_at.present? && code.expires_at <= Time.current
        return render(json: { error: 'already_used' }, status: :bad_request) if code.used_at.present?

        relationship = code.relationship
        return render(json: { error: 'invalid_status' }, status: :bad_request) unless relationship.PENDING?
        return render(json: { error: 'already_member' }, status: :bad_request) if relationship.users.exists?(id: current_user.id)

        if relationship.users.count == 1
          ActiveRecord::Base.transaction do
            RelationshipMembership.create!(relationship: relationship, user: current_user, role: 'PARTNER')
            current_user.update!(current_relationship_id: relationship.id)
            relationship.users.reload.each { |u| u.update!(current_relationship_id: relationship.id) }
            code.update!(used_at: Time.current)
          end
          render json: relationship_payload(relationship)
        else
          render json: { error: 'already_paired' }, status: :bad_request
        end
      end

      private

      def update_params
        params.permit(:relationship_type, :distance)
      end

      def ensure_active_or_pending_relationship!
        relationship = current_user.current_relationship
        return render(json: { error: 'no_relationship' }, status: :not_found) if relationship.nil?
        return render(json: { error: 'relationship_ended' }, status: :bad_request) if relationship.ENDED?
      end

      def relationship_payload(relationship)
        invite = InviteCode.where(relationship: relationship)
                           .order(created_at: :desc)
                           .first

        partner = relationship.users.where.not(id: current_user.id).first
        latest_device = partner&.client_devices&.order(updated_at: :desc)&.first
        partner_tz_offset = latest_device&.timezone_offset_seconds
        partner_tz_name = latest_device&.timezone_name

        {
          uuid: relationship.uuid,
          status: relationship.status,
          distance: relationship.distance,
          type: relationship.type,
          timezone_name: relationship.timezone_name,
          timezone_offset_seconds: relationship.timezone_offset_seconds,
          invite_code: invite.nil? ? nil : { code: invite.code, expires_at: invite.expires_at },
          partner: partner.nil? ? nil : { uuid: partner.uuid, name: partner.name, image_path: partner.image_path, timezone_name: partner_tz_name, timezone_offset_seconds: partner_tz_offset },
        }
      end

      # Invite creation centralized in InviteCodeService
      def invite_code_service
        @invite_code_service ||= InviteCodeService.new
      end
    end
  end
end


