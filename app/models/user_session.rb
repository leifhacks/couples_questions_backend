# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Model for User Sessions (refresh tokens)
#-------------------------------------------------------------------------------
class UserSession < ApplicationRecord
  belongs_to :user
end


