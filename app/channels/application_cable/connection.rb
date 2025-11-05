module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :web_socket_connection

    def connect
      decode_data
      self.web_socket_connection = get_connection
    end

    private

    def decode_data
      parser = Base64Decoder.new

      decoded_hash = parser.call(request.params[:data])
      request.params.delete('data')
      decoded_hash.each do |key, value|
        request.params[key] = value
      end
    end

    def get_connection
      device_token = request.params[:device_token]
      if device_token.nil?
        Rails.logger.info("#{self.class}.#{__method__}: Missing device token: #{request.params}")
        return reject_unauthorized_connection
      end

      device = ClientDevice.find_by(device_token: device_token)
      if device.nil?
        Rails.logger.info("#{self.class}.#{__method__}: Missing device: #{request.params}")
        return reject_unauthorized_connection
      end

      web_socket_connection = device.web_socket_connection
      web_socket_connection&.destroy!

      WebSocketConnection.create!(client_device: device)
    end
  end
end
