# frozen_string_literal: true

#-------------------------------------------------------------------------------
# This class sends push messages via FCM
#-------------------------------------------------------------------------------
class FcmPushService
  DEFAULT_OPTIONS = {
    notification: { body: 'message', title: 'title' },
    android: { priority: 'high' },
    data: { click_action: 'FLUTTER_NOTIFICATION_CLICK' }
  }

  def initialize(fcm_client, store_service, json_parser, options = DEFAULT_OPTIONS)
    @fcm_client = fcm_client
    @store_service = store_service
    @json_parser = json_parser
    @options = options
  end

  def call(tokens, title, body, collapse_key = nil, data = {})
    options = custom_options(body, title, collapse_key, data)

    tokens.each_slice(100) do |token_batch|
      response = @fcm_client.send(token_batch, options)
      @store_service.call(response)
    end
  end

  private

  def custom_options(body, title, collapse_key, data)
    options = @options.dup
    options[:android][:collapse_key] = collapse_key if !collapse_key.nil? && options.key?(:android)
    options[:notification][:body] = body if options.key?(:notification)
    options[:notification][:title] = title if options.key?(:notification)
    options[:data].merge(data) if options.key?(:data)
    options
  end
end
