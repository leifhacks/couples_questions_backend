class BaseBroadcastWorker
  include Sidekiq::Worker

  sidekiq_options retry: false

  MAX_ATTEMPTS = 3
  RETRY_INTERVAL_SECONDS = 3

  def perform(device_id, user_id, resource_id)
    MAX_ATTEMPTS.times do |attempt|
      Rails.logger.info("#{self.class}.#{__method__}: Attempt no #{attempt}")

      device = ClientDevice.find_by(id: device_id)
      user = User.find_by(id: user_id)
      resource = find_resource(resource_id)
      return if device.nil? || user.nil? || resource.nil?

      if attempt.positive?
        unless device.user_id == user.id
          Rails.logger.info("#{self.class}.#{__method__} skipping: device #{device_id} no longer belongs to user #{user_id}")
          return
        end

        unless resource_still_valid?(user, resource)
          return
        end
      end

      connection = device.web_socket_connection
      if connection.present?
        BroadcastWorker.perform_async(connection.uuid, build_message(user, resource))
        return
      end

      next if attempt >= MAX_ATTEMPTS - 1

      sleep(RETRY_INTERVAL_SECONDS)
    end

    Rails.logger.info("#{self.class}.#{__method__}: exhausted #{MAX_ATTEMPTS} attempts")
  end

  private

  def find_resource(_resource_id)
    raise NotImplementedError, "#{self.class} must implement ##{__method__}"
  end

  def resource_still_valid?(_user, _resource)
    true
  end

  def build_message(_user, _resource)
    raise NotImplementedError, "#{self.class} must implement ##{__method__}"
  end
end

