#-------------------------------------------------------------------------------
# Worker which generates broadcasts messages
#-------------------------------------------------------------------------------
class BroadcastWorker
  include Sidekiq::Worker

  def perform(connection_uuid, message)
    Rails.logger.info("#{self.class}.#{__method__}: #{message}")
    channel_name = WebSocketChannel.channel_name_from_uuid(connection_uuid)
    ActionCable.server.broadcast(channel_name, message)
  end
end
