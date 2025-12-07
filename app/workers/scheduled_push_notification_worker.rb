# frozen_string_literal: true
class ScheduledPushNotificationWorker
  include Sidekiq::Worker

  def perform
    date = DateTime.now.utc
    notifications = PushNotification.where(hours: date.hour, minutes: date.min)
    return if notifications.empty?

    @push_service = DevicesPushService.new(ClientDevice)
    messages = get_messages(notifications)
    post_messages(messages)
  end

  private

  def get_messages(notifications)
    messages = {ios: { de: [], en: [] }, android: { de: [], en: [] } }
    notifications.each do |notification|
      notification.user.client_devices.each do |device|
        platform = device.platform_from_token.to_sym
        platform = :android unless messages.key?(platform)
        iso_code = device.language_code.to_sym
        iso_code = :en unless messages[platform].key?(iso_code)
        messages[platform][iso_code].push(device.device_token)
      end
    end
    messages
  end

  def post_messages(messages)
    messages.each do |platform, map|
      map.each do |lang, tokens|
        title = lang == :de ? 'Erinnerung' : 'Reminder'
        body = lang == :de ? 'Es ist Zeit, die Frage für heute zu beantworten.' : 'It\'s time to answer the question for today.'
        @push_service.call(tokens, platform.to_s, title, body)
      end
    end
  end
end
