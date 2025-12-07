# frozen_string_literal: true
class PushNotificationWorker
  include Sidekiq::Worker

  def perform(device_tokens, platform, title, body)
    push_service = DevicesPushService.new(ClientDevice)
    push_service.call(device_tokens, platform, title, body)
  end
end
