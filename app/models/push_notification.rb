# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Model for push notifications
#-------------------------------------------------------------------------------
class PushNotification < ApplicationRecord
  belongs_to :user

  def payload
    {
      notification_type: notification_type,
      hours: hours,
      minutes: minutes
    }
  end
end
