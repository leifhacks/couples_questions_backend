# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Model for Users containing info about a user
#-------------------------------------------------------------------------------
class User < IdentifiedRecord
  IDENTIFIER_REGEX = /\A[0-9a-f]{8}\z/
  NAME_REGEX = /\A[A-Za-z0-9ÄäÖöÜüß\-_ ]*\z/

  SECONDS_PER_MINUTE = 60
  SECONDS_PER_HOUR = 60 * SECONDS_PER_MINUTE
  SECONDS_PER_DAY = 24 * SECONDS_PER_HOUR

  has_many :client_devices, dependent: :destroy
  has_many :user_sessions, dependent: :destroy
  has_many :push_notifications, dependent: :destroy
  has_many :created_invite_codes, class_name: 'InviteCode', foreign_key: 'created_by_user_id', dependent: :destroy
  has_many :relationship_memberships, dependent: :destroy
  has_many :relationships, through: :relationship_memberships
  has_many :answers, dependent: :destroy

  belongs_to :current_relationship, class_name: 'Relationship', optional: true
  belongs_to :favorite_category, class_name: 'Category', optional: true

  before_save { self.identifier ||= generate_random_uuid(8, :identifier) }
  before_save { self.uuid ||= generate_random_uuid }

  validates :name, format: { with: NAME_REGEX }, allow_nil: true

  def preferred_language_code
    latest_device = client_devices.order(updated_at: :desc).first
    language = latest_device&.language_code
    language.present? ? language : 'en'
  end
  
  def latest_timezone_components
    device = client_devices.order(updated_at: :desc).first
    return [nil, nil, nil] if device.nil?
    [device.timezone_name, device.timezone_offset_seconds, device.updated_at]
  end

  def latest_device_offset
    client_devices.order(updated_at: :desc).pick(:timezone_offset_seconds)
  end

  def payload
    {
      uuid: uuid,
      name: name,
      favorite_category_uuid: favorite_category&.uuid,
      image_path: image_path,
      current_relationship_uuid: current_relationship&.uuid
    }
  end

  def partner_payload
    latest_device = client_devices.order(updated_at: :desc).first
    timezone_name = latest_device&.timezone_name
    timezone_offset_seconds = latest_device&.timezone_offset_seconds
    {
      uuid: uuid,
      name: name,
      image_path: image_path,
      timezone_name: timezone_name,
      timezone_offset_seconds: timezone_offset_seconds,
    }
  end

  def tokens_by_platform_and_language
    tokens_by_platform_and_lang = Hash.new do |platform_hash, platform|
      platform_hash[platform] = Hash.new { |lang_hash, lang| lang_hash[lang] = [] }
    end

    client_devices.where.not(device_token: [nil, '']).find_each do |device|
      platform = device.platform_from_token
      next if platform.nil?

      language = device.language_code.to_s.downcase == 'de' ? 'de' : 'en'
      tokens_by_platform_and_lang[platform][language] << device.device_token
    end

    tokens_by_platform_and_lang
  end

  # Recalculate stored UTC reminder times so the perceived local time stays stable
  # when the user's effective timezone offset changes. The new offset is derived
  # from the user's most recent devices.
  def adjust_push_notifications_for_timezone_change!(from_offset_seconds:)
    to_offset_seconds = latest_device_offset

    return if from_offset_seconds.nil? || to_offset_seconds.nil?
    return if from_offset_seconds == to_offset_seconds

    delta_seconds = from_offset_seconds - to_offset_seconds

    push_notifications.where.not(hours: nil, minutes: nil).find_each do |notification|
      total_seconds = (notification.hours * SECONDS_PER_HOUR) + (notification.minutes * SECONDS_PER_MINUTE)
      adjusted_seconds = (total_seconds + delta_seconds) % SECONDS_PER_DAY
      new_hours, remainder = adjusted_seconds.divmod(SECONDS_PER_HOUR)
      new_minutes = remainder / SECONDS_PER_MINUTE

      next if notification.hours == new_hours && notification.minutes == new_minutes

      notification.update!(hours: new_hours, minutes: new_minutes)
    end
  end

  private

  def self.cleanup
    deleted_users =  User.where.missing(:client_devices)
    result = deleted_users.size
    deleted_users.destroy_all

    result
  end
end
