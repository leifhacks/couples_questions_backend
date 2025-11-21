# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Model for Answers submitted by Users for assigned Questions
#-------------------------------------------------------------------------------
class Answer < UuidRecord
  belongs_to :question_assignment
  belongs_to :user

  after_commit :broadcast_status_change, on: [:create, :update]

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

  private

  def broadcast_status_change
    question_assignment.relationship.users.each do |user|
      next if user.id == self.user.id

      user.client_devices.each do |device|
        next if Current.skip_broadcast_device?(device)

        AnswerBroadcastWorker.perform_async(device.id, user.id, self.id)
      end
    end
  end
end
