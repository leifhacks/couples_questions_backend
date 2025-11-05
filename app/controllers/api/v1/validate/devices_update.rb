# frozen_string_literal: true

module Api
  module V1
    module Validate
      module Devices
        class Update
          include ActiveModel::Validations

          attr_accessor :device_token, :platform, :iso_code, :timezone_name, :timezone_offset_seconds

          validates :iso_code, format: { with: ClientDevice::ISO_CODE_REGEX }, allow_nil: true, allow_blank: true

          # No required fields; allow partial updates
          def initialize(params = {})
            @device_token = params[:device_token]
            @platform = params[:platform]
            @iso_code = params[:iso_code]
            @timezone_name = params[:timezone_name]
            @timezone_offset_seconds = params[:timezone_offset_seconds]
          end
        end
      end
    end
  end
end


