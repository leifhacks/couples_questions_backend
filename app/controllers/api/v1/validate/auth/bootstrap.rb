# frozen_string_literal: true

module Api
  module V1
    module Validate
      module Auth
        class Bootstrap
          include ActiveModel::Validations

          attr_accessor :name, :favorite_category_uuid, :distance, :description,
                        :device_token, :platform, :iso_code, :timezone_name, :timezone_offset_seconds, :device

          validates :name, presence: true
          validates :device_token, presence: true
          validates :iso_code, presence: true, format: { with: ClientDevice::ISO_CODE_REGEX }

          def initialize(params = {})
            # decoder has already expanded params; accept nested device or flat
            dev = params[:device] || {}
            @name = params[:name]
            @favorite_category_uuid = params[:favorite_category_uuid]
            @distance = params[:distance]
            @description = params[:description]
            @device_token = dev[:device_token] || params[:device_token]
            @platform = dev[:platform] || params[:platform]
            @iso_code = dev[:iso_code] || params[:iso_code]
            @timezone_name = dev[:timezone_name] || params[:timezone_name]
            @timezone_offset_seconds = dev[:timezone_offset_seconds] || params[:timezone_offset_seconds]
          end
        end
      end
    end
  end
end



