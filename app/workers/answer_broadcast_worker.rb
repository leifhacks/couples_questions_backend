#-------------------------------------------------------------------------------
# Worker which broadcasts answer updates to connected clients
#-------------------------------------------------------------------------------
class AnswerBroadcastWorker < BaseBroadcastWorker
  def perform(device_id, user_id, answer_id, include_answer_body)
    super(device_id, user_id, answer_id)
    @include_answer_body = include_answer_body
  end

  private

  def find_resource(answer_id)
    Answer.find_by(id: answer_id)
  end

  def resource_still_valid?(user, answer)
    relationship = answer.question_assignment.relationship
    unless relationship.users.exists?(id: user.id)
      Rails.logger.info("#{self.class}.perform skipping: user #{user.id} no longer belongs to relationship #{relationship.id}")
      return false
    end

    true
  end

  def build_message(user, answer)
    {
      'event' => 'answer_updated',
      'answer' => answer.payload(include_body: @include_answer_body)
    }.as_json
  end
end
