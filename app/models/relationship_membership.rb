# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Join model between User and Relationship
#-------------------------------------------------------------------------------
class RelationshipMembership < ApplicationRecord
  enum role: { OWNER: 'OWNER', PARTNER: 'PARTNER' }

  belongs_to :relationship
  belongs_to :user
end


