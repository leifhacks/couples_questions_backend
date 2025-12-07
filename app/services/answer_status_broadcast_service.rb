#!/usr/bin/env ruby
# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Service that broadcasts answer status changes to all devices in a relationship
#-------------------------------------------------------------------------------
class AnswerStatusBroadcastService
  def call(answer)
    question_assignment = answer.question_assignment
    relationship = question_assignment&.relationship
    return if relationship.nil?

    relationship_users = relationship.users.to_a
    include_answer_body = all_relationship_users_answered?(question_assignment, relationship_users)

    relationship_users.each do |user|
      user.client_devices.each do |device|
        next if Current.skip_broadcast_device?(device)

        AnswerBroadcastWorker.perform_async(
          device.id,
          user.id,
          answer.id,
          include_answer_body || user.id == answer.user.id
        )
      end
    end
  end

  private

  def all_relationship_users_answered?(question_assignment, relationship_users)
    expected_user_ids = relationship_users.map(&:id)
    return false if expected_user_ids.blank?

    answered_user_ids = question_assignment.answers.select(:user_id).distinct.pluck(:user_id)
    (expected_user_ids - answered_user_ids).empty?
  end
end

