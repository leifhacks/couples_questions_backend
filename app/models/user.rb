# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Model for Users containing info about a user
#-------------------------------------------------------------------------------
class User < IdentifiedRecord
  IDENTIFIER_REGEX = /\A[0-9a-f]{8}\z/
  NAME_REGEX = /\A[A-Za-z0-9ÄäÖöÜüß\-_ ]+\z/

  has_many :client_devices, dependent: :destroy
  has_many :push_notifications, dependent: :destroy

  before_save { self.identifier ||= generate_random_uuid(8, :identifier) }

  def self.cleanup
    deleted_users =  User.where.missing(:client_devices)
    result = deleted_users.size
    deleted_users.destroy_all

    result
  end
end
