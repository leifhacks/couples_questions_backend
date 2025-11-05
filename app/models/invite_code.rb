# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Model for Invite Codes used to pair Users into a Relationship
#-------------------------------------------------------------------------------
class InviteCode < ApplicationRecord
  belongs_to :relationship
  belongs_to :created_by_user, class_name: 'User'
end


