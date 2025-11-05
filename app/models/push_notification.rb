# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Model for push notifications
#-------------------------------------------------------------------------------
class PushNotification < ApplicationRecord
  belongs_to :user
end
