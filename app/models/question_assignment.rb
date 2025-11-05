# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Model for Question Assignments to Relationships per day
#-------------------------------------------------------------------------------
class QuestionAssignment < UuidRecord
  belongs_to :relationship
  belongs_to :question

  has_many :answers, dependent: :destroy
end


