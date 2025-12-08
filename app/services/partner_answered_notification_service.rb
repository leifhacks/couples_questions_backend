#!/usr/bin/env ruby
# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Service that nudges a partner via push notification when the other answers
#-------------------------------------------------------------------------------
class PartnerAnsweredNotificationService
  def initialize(push_worker: PushNotificationWorker)
    @push_worker = push_worker
  end

  def call(answer)
    question_assignment = answer.question_assignment
    relationship = question_assignment&.relationship
    return if relationship.nil?

    answering_user = answer.user
    partners = relationship.users.where.not(id: answering_user.id)
    return if partners.empty?

    all_users_answered = all_relationship_users_answered?(question_assignment, relationship.users)
    if all_users_answered
      partners.each { |partner| enqueue_answer_revealed(partner) }
    else
      partners.each { |partner| enqueue_answer_added(question_assignment, partner) }
    end
  end

  private

  def all_relationship_users_answered?(question_assignment, relationship_users)
    expected_user_ids = relationship_users.map(&:id)
    return false if expected_user_ids.blank?

    answered_user_ids = question_assignment.answers.select(:user_id).distinct.pluck(:user_id)
    (expected_user_ids - answered_user_ids).empty?
  end

  def enqueue_answer_revealed(user)
    return unless user.push_notifications.where(notification_type: :ANSWER_REVEALED).exists?

    tokens_by_platform_and_lang = user.tokens_by_platform_and_language
    enqueue_notifications(tokens_by_platform_and_lang, ANSWER_REVEALED_NOTIFICATION_TEXT)
  end

  def enqueue_answer_added(question_assignment, partner)
    return unless partner.push_notifications.where(notification_type: :ANSWER_ADDED).exists?
    return if already_answered?(question_assignment, partner)

    tokens_by_platform_and_lang = partner.tokens_by_platform_and_language
    enqueue_notifications(tokens_by_platform_and_lang, ANSWER_ADDED_NOTIFICATION_TEXT)
  end

  def already_answered?(question_assignment, partner)
    question_assignment.answers.where(user_id: partner.id).exists?
  end

  def enqueue_notifications(tokens_by_platform_and_lang, notification_text)
    return if tokens_by_platform_and_lang.empty?

    tokens_by_platform_and_lang.each do |platform, tokens_by_lang|
      tokens_by_lang.each do |language, tokens|
        next if tokens.empty?

        title, body = notification_text[language]
        @push_worker.perform_async(tokens, platform, title, body)
      end
    end
  end
end
