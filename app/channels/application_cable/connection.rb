module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :web_socket_connection

    def connect
      decode_data
      user = authenticate_user
      self.web_socket_connection = establish_connection_for(user)
    end

    private

    def decode_data
      encoded = request.params[:data]
      return if encoded.blank?

      parser = Base64Decoder.new
      decoded_hash = parser.call(encoded)

      request.params.delete('data')
      decoded_hash.each do |key, value|
        request.params[key] = value
      end
    rescue JSON::ParserError => e
      Rails.logger.info("#{self.class}.#{__method__}: Unable to decode params: #{e.message}")
      reject_unauthorized_connection
    end

    def authenticate_user
      token = AccessTokenFetcher.new(request).call
      if token.blank?
        Rails.logger.info("#{self.class}.#{__method__}: Missing access token: #{request.params}")
        reject_unauthorized_connection
      end

      user = token_service.user_from_access_token(token)
      if user.nil?
        Rails.logger.info("#{self.class}.#{__method__}: Invalid access token: #{request.params}")
        reject_unauthorized_connection
      end

      user
    end

    def establish_connection_for(user)
      device_token = request.params[:device_token]
      if device_token.blank?
        Rails.logger.info("#{self.class}.#{__method__}: Missing device token: #{request.params}")
        reject_unauthorized_connection
      end

      device = ClientDevice.find_by(device_token: device_token)
      if device.nil?
        Rails.logger.info("#{self.class}.#{__method__}: Missing device: #{request.params}")
        reject_unauthorized_connection
      end

      if user.nil? || device.user_id != user.id
        Rails.logger.info("#{self.class}.#{__method__}: Device does not belong to current user: #{request.params}")
        reject_unauthorized_connection
      end

      previous_connection = device.web_socket_connection

      ActiveRecord::Base.transaction do
        connection = WebSocketConnection.create!
        device.update!(web_socket_connection: connection)
        previous_connection&.destroy!
        connection
      end
    end

    def token_service
      @token_service ||= TokenService.new
    end
  end
end
