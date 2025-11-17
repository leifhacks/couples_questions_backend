# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Model for Answers submitted by Users for assigned Questions
#-------------------------------------------------------------------------------
class Answer < UuidRecord
  belongs_to :question_assignment
  belongs_to :user

  def payload
    {
      uuid: uuid,
      body: body
    }
  end
end
