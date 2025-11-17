# frozen_string_literal: true

#-----------------------------------------------------------------------------
# The ApplicationCable Channel for Web Socket Connections
#-----------------------------------------------------------------------------
class WebSocketChannel < ApplicationCable::Channel
  def self.channel_name_from_uuid(connection_uuid)
    "WebSocket-#{connection_uuid}"
  end

  def subscribed
    user = connection_user

    unless authorized_subscriber?(user)
      Rails.logger.info("#{self.class}.#{__method__}: Unauthorized subscription attempt: #{params}")
      reject
      return
    end

    Rails.logger.info("#{self.class}.#{__method__}: #{web_socket_connection.uuid}, user: #{user&.uuid}, #{params}")

    channel_name = WebSocketChannel.channel_name_from_uuid(web_socket_connection.uuid)
    stream_from(channel_name)

    # connection.transmit error: 'not implemented'
    # reject
  end

  def unsubscribed
    Rails.logger.info("#{self.class}.#{__method__}: #{params}")
    web_socket_connection&.destroy!
    stop_all_streams
  end

  private

  def authorized_subscriber?(user)
    return false if web_socket_connection.nil?

    device = web_socket_connection.client_device
    return false if device.nil?

    user.present? && device.user_id == user.id
  end

  def connection_user
    @connection_user ||= web_socket_connection&.client_device&.user
  end
end
