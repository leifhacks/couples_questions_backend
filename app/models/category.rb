# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Model for Question Categories
#-------------------------------------------------------------------------------
class Category < UuidRecord
  has_many :questions
end


