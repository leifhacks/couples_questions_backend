# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Model for Records with uuid
#-------------------------------------------------------------------------------
class UuidRecord < IdentifiedRecord
  self.abstract_class = true

  before_save { self.uuid ||= generate_random_uuid }
end
