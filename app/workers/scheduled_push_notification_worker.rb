# frozen_string_literal: true
class ScheduledPushNotificationWorker
  include Sidekiq::Worker

  def perform
    date = DateTime.now.utc
    notifications = PushNotification.where(hours: date.hour, minutes: date.min)
    return if notifications.empty?

    @push_service = DevicesPushService.new(ClientDevice)
    messages = get_messages(notifications)
    post_messages(messages)
  end

  private

  def get_messages(notifications)
    messages = Hash.new do |platform_hash, platform|
      platform_hash[platform] = Hash.new { |lang_hash, lang| lang_hash[lang] = [] }
    end

    notifications.each do |notification|
      user = notification.user
      next unless should_send_reminder_for?(user)

      tokens_by_platform_and_lang = user.tokens_by_platform_and_language

      tokens_by_platform_and_lang.each do |platform, tokens_by_lang|
        tokens_by_lang.each do |language, tokens|
          messages[platform][language].concat(tokens)
        end
      end
    end

    messages
  end

  def post_messages(messages)
    messages.each do |platform, language_map|
      language_map.each do |language, tokens|
        title, body = notification_text_for(language)
        @push_service.call(tokens, platform.to_s, title, body)
      end
    end
  end

  def notification_text_for(language)
    if language.to_s == 'de'
      ['Erinnerung', 'Es ist Zeit, die Frage für heute zu beantworten.']
    else
      ['Reminder', "It's time to answer the question for today."]
    end
  end

  def should_send_reminder_for?(user)
    relationship = user.current_relationship
    return false if relationship.nil? || !relationship.ACTIVE?

    question_date = relationship.current_date_for(user)
    assignment = QuestionAssignment.find_by(relationship: relationship, question_date: question_date)
    return false if assignment.nil?

    !assignment.answers.where(user_id: user.id).exists?
  end

end
