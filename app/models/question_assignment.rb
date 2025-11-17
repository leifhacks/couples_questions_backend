# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Model for Question Assignments to Relationships per day
#-------------------------------------------------------------------------------
class QuestionAssignment < UuidRecord
  belongs_to :relationship
  belongs_to :question

  has_many :answers, dependent: :destroy

  def payload(lang)
    {
      uuid: uuid,
      relationship_uuid: relationship.uuid,
      question_date: question_date,
      question: question.body(lang)
    }
  end
end


