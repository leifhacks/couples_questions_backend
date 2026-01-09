# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Model for Question Assignments to Relationships per day
#-------------------------------------------------------------------------------
class QuestionAssignment < UuidRecord
  belongs_to :relationship
  belongs_to :question

  has_many :answers, dependent: :destroy

  def payload(viewer:)
    assignments_map = answered_by_date

    payload = {
      uuid: uuid,
      relationship_uuid: relationship.uuid,
      question_date: question_date,
      question: question.payload(viewer.preferred_language_code),
      answers_streak_days: consecutive_answer_days(assignments_map, question_date),
      total_answered_questions: assignments_map.size
    }
    return payload unless viewer.present?

    my_answer = answers.find { |a| a.user_id == viewer.id }
    partner_answer = answers.find { |a| a.user_id != viewer.id }

    partner_visible = my_answer.present? && partner_answer.present?

    payload[:my_answer] = my_answer&.payload
    payload[:partner_answer] = partner_answer&.payload(include_body: partner_visible)
    payload
  end

  private

  def answered_by_date
    participant_ids = relationship.users.pluck(:id)
    return {} if participant_ids.blank?

    assignments = relationship.question_assignments
                              .where('question_date <= ?', question_date)
                              .includes(:answers)

    answered_by_date = {}
    assignments.each do |assignment|
      next unless assignment.answered_by_all_participants?(participant_ids)

      answered_by_date[assignment.question_date] = assignment
    end

    answered_by_date
  end

  def answered_by_all_participants?(participant_ids)
    answered_ids = answers.map(&:user_id).uniq
    (participant_ids - answered_ids).empty?
  end

  def consecutive_answer_days(answered_by_date, start_date)
    return 0 if answered_by_date.blank?

    streak = 0
    date = start_date
    loop do
      assignment = answered_by_date[date]
      break if assignment.nil?

      streak += 1
      date -= 1.day
    end
    streak
  end
end


