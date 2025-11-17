# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Model for Relationships between two Users
#-------------------------------------------------------------------------------
class Relationship < UuidRecord
  enum status: { PENDING: 'PENDING', ACTIVE: 'ACTIVE', ENDED: 'ENDED' }

  has_many :relationship_memberships, dependent: :destroy
  has_many :users, through: :relationship_memberships

  has_many :question_assignments, dependent: :destroy
  has_many :answers, through: :question_assignments

  before_save :set_timezone_from_calculation
  before_save :cache_status_change_user_ids, if: -> { will_save_change_to_status? }
  after_commit :broadcast_status_change, on: [:create, :update], if: -> { saved_change_to_status? }

  def recalculate_timezone!
    name, offset = calculate_timezone_components
    update!(timezone_name: name, timezone_offset_seconds: offset)
  end

  def payload
    {
      uuid: uuid,
      status: status,
      distance: distance,
      type: relationship_type,
      timezone_name: timezone_name,
      timezone_offset_seconds: timezone_offset_seconds,
    }
  end

  private

  # Determine timezone from partners' latest devices.
  # Returns [timezone_name, timezone_offset_seconds], preferring largest offset; tie-breaker by latest updated_at.
  def calculate_timezone_components
    latest_candidates = users.map do |u|
      name, offset, updated_at = u.latest_timezone_components
      next nil if offset.nil?
      [name, offset, updated_at]
    end.compact

    return [nil, nil] if latest_candidates.empty?

    name, offset, _updated = latest_candidates.max_by { |(_name, offset, updated_at)| [offset, updated_at] }
    [name, offset]
  end

  def set_timezone_from_calculation
    return if users.none?
    name, offset = calculate_timezone_components
    self.timezone_name = name
    self.timezone_offset_seconds = offset
  end

  def cache_status_change_user_ids
    @status_change_user_ids = users.pluck(:id)
  end

  def broadcast_status_change
    user_ids = @status_change_user_ids.presence || users.pluck(:id)
    return if user_ids.blank?

    User.includes(client_devices: :web_socket_connection).where(id: user_ids).find_each do |user|
      message = relationship_status_message_for(user)
      user.client_devices.each do |device|
        connection = device.web_socket_connection
        next if connection.nil?
        next if skip_broadcast_device?(device)

        BroadcastWorker.perform_async(connection.uuid, message)
      end
    end
  ensure
    @status_change_user_ids = nil
  end

  def relationship_status_message_for(user)
    {
      'event' => 'relationship_status_changed',
      'relationship_uuid' => uuid,
      'status' => status,
      'user_uuid' => user.uuid
    }
  end

  def skip_broadcast_device?(device)
    initiator_device_token = Current.respond_to?(:initiator_device_token) ? Current.initiator_device_token : nil
    return false if initiator_device_token.blank?

    device.device_token == initiator_device_token
  end
end


