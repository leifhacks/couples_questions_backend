#-------------------------------------------------------------------------------
# Worker which broadcasts relationship updates to connected clients
#-------------------------------------------------------------------------------
class RelationshipBroadcastWorker
  include Sidekiq::Worker

  sidekiq_options retry: false

  MAX_RETRY_WINDOW_SECONDS = 10
  RETRY_INTERVAL_SECONDS = 2

  def perform(device_id, user_id, relationship_id, attempt = 0)
    Rails.logger.info("#{self.class}.#{__method__}")

    device = Device.find_by(id: device_id)
    user = User.find_by(id: user_id)
    relationship = Relationship.find_by(id: relationship_id)
    return if device.nil? || user.nil? || relationship.nil?

    if attempt.positive?
      unless device.user_id == user.id
        Rails.logger.info(
          "#{self.class}.#{__method__} skipping: device #{device_id} no longer belongs to user #{user_id}"
        )
        return
      end

      unless relationship.users.exists?(id: user.id)
        Rails.logger.info(
          "#{self.class}.#{__method__} skipping: user #{user_id} no longer belongs to relationship #{relationship_id}"
        )
        return
      end
    end

    connection = device.web_socket_connection
    if connection.nil?
      schedule_retry(device_id, user_id, relationship_id, attempt)
      return
    end

    message = relationship_status_message(user, relationship)
    BroadcastWorker.perform_async(connection.uuid, message)
  end

  private

  def schedule_retry(device_id, user_id, relationship_id, attempt)
    remaining_window = MAX_RETRY_WINDOW_SECONDS - (attempt * RETRY_INTERVAL_SECONDS)
    return if remaining_window <= 0

    delay_seconds = [remaining_window, RETRY_INTERVAL_SECONDS].min
    self.class.perform_in(delay_seconds, device_id, user_id, relationship_id, attempt + 1)
  end

  def relationship_status_message(user, relationship)
    {
      'event' => 'relationship_updated',
      'relationship' => relationship.extended_payload(user)
    }.as_json
  end
end
