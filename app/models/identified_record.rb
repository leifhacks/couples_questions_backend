# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Model for Records with some unique attribute based on uuid
#-------------------------------------------------------------------------------
class IdentifiedRecord < ApplicationRecord
  UUID_REGEX = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/

  self.abstract_class = true

  def generate_random_uuid(length = nil, attribute = 'uuid')
    loop do
      base_uuid = Sysrandom.uuid
      return base_uuid if length.nil? || length > base_uuid.length

      uuid = base_uuid[0...length]

      return uuid unless self.class.exists?(["#{attribute} LIKE ?", "%#{uuid}%"])
    end
  end
end
