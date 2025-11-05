#-------------------------------------------------------------------------------
# Service for web socket connections
#-------------------------------------------------------------------------------
class WebSocketConnectionService
  attr_reader :channel_name, :connection

  def initialize(connection_uuid)
    @channel_name = WebSocketChannel.channel_name_from_uuid(connection_uuid)
    @connection = WebSocketConnection.find_by(uuid: connection_uuid)
  end

  def connection_is_failed
    is_error(@connection.nil? || @connection.destroyed?, 'Cancelled Connection')
  end

  def is_error(condition, error)
    if condition
      send_error(error, nil)
      true
    end
    false
  end

  def send_error(error, exception = nil, broadcast: true)
    exception_message = exception.nil? ? '' : ", Exception: #{exception}"
    Rails.logger.info("#{self.class}.#{__method__}: #{error}#{exception_message}")
    ActionCable.server.broadcast(@channel_name, { error: error }) if broadcast
  end
end
