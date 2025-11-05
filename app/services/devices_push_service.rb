# frozen_string_literal: true

#-------------------------------------------------------------------------------
# This class creates push messages to send to a set of devices
#-------------------------------------------------------------------------------
class DevicesPushService
  include Sidekiq::Worker

  def initialize(client_model = nil)
    store_service = StorePushResponseService.new(client_model)
    initialize_fcm(store_service)
    initialize_apns(store_service)
  end

  def call(tokens, platform, title, body, collapse_key: nil, data: {})
    if platform == 'android'
      @fcm_service.call(tokens, title, body, collapse_key, data)
    elsif platform == 'ios'
      @apns_service.call(tokens, title, body, collapse_key, data)
    end
  end

  private

  def initialize_fcm(store_service)
    fcm_client = FcmClientService.new
    @fcm_service = FcmPushService.new(fcm_client, store_service, JSON)
  end

  def initialize_apns(store_service)
    @apns_service = ApnsPushService.new(store_service)
  end
end
