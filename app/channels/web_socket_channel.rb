# frozen_string_literal: true

#-----------------------------------------------------------------------------
# The ApplicationCable Channel for Web Socket Connections
#-----------------------------------------------------------------------------
class WebSocketChannel < ApplicationCable::Channel
  def self.channel_name_from_uuid(connection_uuid)
    "WebSocket-#{connection_uuid}"
  end

  def subscribed
    Rails.logger.info("#{self.class}.#{__method__}: #{web_socket_connection.uuid}, #{params}")

    channel_name = WebSocketChannel.channel_name_from_uuid(web_socket_connection.uuid)
    stream_from(channel_name)

    # connection.transmit error: 'not implemented'
    # reject
  end

  def unsubscribed
    Rails.logger.info("#{self.class}.#{__method__}: #{params}")
    web_socket_connection.destroy!
    stop_all_streams
  end
end
