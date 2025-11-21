# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Model for Answers submitted by Users for assigned Questions
#-------------------------------------------------------------------------------
class Answer < UuidRecord
  belongs_to :question_assignment
  belongs_to :user

  after_commit :broadcast_status_change, on: [:create, :update]

  def payload(include_body: true)
    {
      uuid: uuid,
      body: include_body ? body : nil,
      reaction: reaction,
      created_at: created_at,
      user_uuid: user.uuid,
      question_assignment_uuid: question_assignment.uuid
    }
  end

  private

  def broadcast_status_change
    relationship_users = question_assignment.relationship.users.to_a
    return unless all_relationship_users_answered?(relationship_users)

    relationship_users.each do |user|
      user.client_devices.each do |device|
        next if Current.skip_broadcast_device?(device)

        AnswerBroadcastWorker.perform_async(device.id, user.id, self.id)
      end
    end
  end

  def all_relationship_users_answered?(relationship_users)
    expected_user_ids = relationship_users.map(&:id)
    return false if expected_user_ids.blank?

    answered_user_ids = question_assignment.answers.select(:user_id).distinct.pluck(:user_id)
    (expected_user_ids - answered_user_ids).empty?
  end
end
