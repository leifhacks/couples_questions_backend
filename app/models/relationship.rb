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
end


