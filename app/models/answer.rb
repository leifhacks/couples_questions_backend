# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Model for Answers submitted by Users for assigned Questions
#-------------------------------------------------------------------------------
class Answer < UuidRecord
  belongs_to :question_assignment
  belongs_to :user

  after_commit :broadcast_status_change, on: [:create, :update]
  after_commit :enqueue_partner_answered_notification, on: :create

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
    AnswerStatusBroadcastService.new.call(self)
  rescue => e
    Rails.logger.error("#{self.class}.#{__method__}: Failed to broadcast answer status, #{e.message}")
  end

  def enqueue_partner_answered_notification
    PartnerAnsweredNotificationService.new.call(self)
  rescue => e
    Rails.logger.error("#{self.class}.#{__method__}: Failed to enqueue partner notification, #{e.message}")
  end
end
