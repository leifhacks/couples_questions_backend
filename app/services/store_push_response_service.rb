# frozen_string_literal: true

#-------------------------------------------------------------------------------
# This class stores the responses from push notification services
#-------------------------------------------------------------------------------
class StorePushResponseService
  def initialize(client_model)
    @client_model = client_model
  end

  def call(response)
    return if @client_model.nil?

    errors = []

    response.each do |token, msg|
      @client_model.where(device_token: token).find_each do |client_device|
        client_device.update(last_response: msg)
      end
      errors.push(msg['error']['status']) if msg.key?('error')
      errors.push(msg['reason']) if msg.key?('reason')
    end

    msg = "Total: #{response.length}, Errors: #{errors.tally}"
    Rails.logger.info("#{self.class}.#{__method__}: #{msg}")
  rescue => e
    Rails.logger.error("#{self.class}.#{__method__}: Failed, #{e.message}")
  end
end
