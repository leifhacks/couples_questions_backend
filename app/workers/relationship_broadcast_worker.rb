#-------------------------------------------------------------------------------
# Worker which broadcasts relationship updates to connected clients
#-------------------------------------------------------------------------------
class RelationshipBroadcastWorker
  include Sidekiq::Worker

  sidekiq_options retry: false

  MAX_ATTEMPTS = 3
  RETRY_INTERVAL_SECONDS = 2

  def perform(device_id, user_id, relationship_id)
    MAX_ATTEMPTS.times do |attempt|
      Rails.logger.info("#{self.class}.#{__method__}: Attempt no #{attempt}")

      device = ClientDevice.find_by(id: device_id)
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
      if connection.present?
        message = relationship_status_message(user, relationship)
        BroadcastWorker.perform_async(connection.uuid, message)
        return
      end

      next if attempt >= MAX_ATTEMPTS - 1

      sleep(RETRY_INTERVAL_SECONDS)
    end

    Rails.logger.info("#{self.class}.#{__method__}: exhausted #{MAX_ATTEMPTS} attempts")
  end

  private

  def relationship_status_message(user, relationship)
    {
      'event' => 'relationship_updated',
      'relationship' => relationship.extended_payload(user)
    }.as_json
  end
end
