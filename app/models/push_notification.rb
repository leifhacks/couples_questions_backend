# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Model for push notifications
#-------------------------------------------------------------------------------
class PushNotification < ApplicationRecord
  enum notification_type: { DAILY_REMINDER: 'DAILY_REMINDER', ANSWER_REVEALED: 'ANSWER_REVEALED', ANSWER_ADDED: 'ANSWER_ADDED' }
  
  belongs_to :user

  def payload
    {
      notification_type: notification_type,
      hours: hours,
      minutes: minutes
    }
  end
end
