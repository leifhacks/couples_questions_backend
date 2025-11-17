# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Model for Users containing info about a user
#-------------------------------------------------------------------------------
class User < IdentifiedRecord
  IDENTIFIER_REGEX = /\A[0-9a-f]{8}\z/
  NAME_REGEX = /\A[A-Za-z0-9ÄäÖöÜüß\-_ ]+\z/

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

  def latest_timezone_components
    device = client_devices.order(updated_at: :desc).first
    return [nil, nil, nil] if device.nil?
    [device.timezone_name, device.timezone_offset_seconds, device.updated_at]
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

  def self.cleanup
    deleted_users =  User.where.missing(:client_devices)
    result = deleted_users.size
    deleted_users.destroy_all

    result
  end
end
