# frozen_string_literal: true

module Api
  #---------------------------------------------------------------------------
  # A controller class for generic requests containing a device token
  #---------------------------------------------------------------------------
  class DeviceTokenController < GenericController
    before_action :parse_device

    def parse_device(create_new: false)
      @device = ClientDevice.find_by(device_token: params[:device_token]) unless params[:device_token].nil?

      if !@device.nil?
        @user = @device.user
        @device.update(iso_code: params[:iso_code]) unless params[:iso_code].nil?
      elsif create_new
        @user = User.create!
        @device = ClientDevice.create!(device_token: params[:device_token], iso_code: params[:iso_code], user: @user)
      else
        Rails.logger.info("#{self.class}.#{__method__}: Device not found #{params}")
        render json: { error: 'unauthorized' }
      end
    end
  end
end
