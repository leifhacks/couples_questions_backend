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
      body: body,
      reaction: reaction,
      created_at: created_at,
      user_uuid: user.uuid,
      question_assignment_uuid: question_assignment.uuid
    }
  end
end
