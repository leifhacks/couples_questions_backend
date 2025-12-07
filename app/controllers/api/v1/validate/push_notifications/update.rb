# frozen_string_literal: true

module Api
  module V1
    module Validate
      module PushNotifications
        class Update
          include ActiveModel::Validations

          attr_accessor :push_notifications

          validates :push_notifications,
                    presence: true,
                    unless: -> { push_notifications.is_a?(Array) && push_notifications.empty? }
          validate :validate_entries

          def initialize(params = {})
            @push_notifications = params[:push_notifications]
          end

          private

          def validate_entries
            unless push_notifications.is_a?(Array)
              errors.add(:push_notifications, 'must be an array')
              return
            end

            push_notifications.each_with_index do |entry, index|
              %i[notification_type hours minutes].each do |field|
                if entry[field].nil?
                  errors.add(:push_notifications, "entry #{index} is missing #{field}")
                end
              end
            end
          end
        end
      end
    end
  end
end

