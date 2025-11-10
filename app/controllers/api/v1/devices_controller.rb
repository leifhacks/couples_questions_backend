# frozen_string_literal: true

module Api
  module V1
    class DevicesController < GenericController
      include ::UserAuthentication

      def initialize
        super(Validate::Devices::Update, Base64Decoder.new)
      end

      before_action :authenticate_user!
      before_action -> { validate_with_validator(Validate::Devices::Update) }, only: [:update]

      # POST /api/v1/devices/:uuid
      def update
        device = ClientDevice.find_by!(uuid: params[:uuid], user: current_user)

        permitted = device_params.to_h.compact_blank
        device.update!(permitted) unless permitted.empty?

        render json: device_payload(device)
      end

      private

      def device_params
        params.permit(:device_token, :platform, :iso_code, :timezone_name, :timezone_offset_seconds)
      end

      def device_payload(device)
        {
          uuid: device.uuid,
          platform: device.platform,
          iso_code: device.iso_code,
          timezone_name: device.timezone_name,
          timezone_offset_seconds: device.timezone_offset_seconds
        }
      end
    end
  end
end
