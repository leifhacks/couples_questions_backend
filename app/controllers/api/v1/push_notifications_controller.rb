# frozen_string_literal: true

module Api
  module V1
    class PushNotificationsController < GenericController
      include ::UserAuthentication

      def initialize
        super(Validate::PushNotifications::Update, Base64Decoder.new)
      end

      skip_before_action :validate_with_validator
      skip_before_action :validate_data, :decode_params, only: [:show]
      before_action :authenticate_user!
      before_action -> { validate_with_validator(Validate::PushNotifications::Update) }, only: [:update]

      # GET /api/v1/push_notifications
      # Returns the push notifications for the authenticated user.
      def show
        render json: current_user.push_notifications.map(&:payload)
      end

      # POST /api/v1/push_notifications
      # Expects decoded params to contain:
      #   push_notifications: [
      #     { user: 'user', notification_type: '...', hours: 8, minutes: 30 },
      #     ...
      #   ]
      #
      # For each entry, creates or updates a PushNotification for the
      # authenticated user with the same notification_type.
      def update
        entries = Array.wrap(params[:push_notifications])

        updated = []

        ActiveRecord::Base.transaction do
          notification_types = entries.map { |entry| entry[:notification_type] }.compact

          if notification_types.empty?
            current_user.push_notifications.destroy_all
          else
            current_user.push_notifications.where.not(notification_type: notification_types).destroy_all
          end

          entries.each do |entry|
            notification_type = entry[:notification_type]
            hours = entry[:hours]
            minutes = entry[:minutes]

            notification = current_user.push_notifications.find_or_initialize_by(notification_type: notification_type)
            notification.hours = hours
            notification.minutes = minutes
            notification.save!

            updated << notification
          end
        end

        render json: {
          push_notifications: updated.map(&:payload)
        }
      end

      # POST /api/v1/push_notifications/delete

      # Destroys all PushNotifications for the authenticated user.
      def destroy
        current_user.push_notifications.destroy_all
        render json: { status: 'ok' }
      end
    end
  end
end

