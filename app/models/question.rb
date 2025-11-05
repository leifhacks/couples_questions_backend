# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Model for Questions
#-------------------------------------------------------------------------------
class Question < UuidRecord
  belongs_to :category

  has_many :question_assignments, dependent: :destroy
end


