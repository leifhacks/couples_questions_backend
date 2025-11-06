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

  def recalculate_timezone!
    name, offset = calculate_timezone_components
    update!(timezone_name: name, timezone_offset_seconds: offset)
  end

  private

  # Determine timezone from partners' latest devices.
  # Returns [timezone_name, timezone_offset_seconds], preferring largest offset; tie-breaker by latest updated_at.
  def calculate_timezone_components
    latest_candidates = users.map do |u|
      d = u.client_devices.order(updated_at: :desc).first
      next nil if d.nil? || d.timezone_offset_seconds.nil?
      [d.timezone_name, d.timezone_offset_seconds, d.updated_at]
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
end


