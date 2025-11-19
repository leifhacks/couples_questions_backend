# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Model for Invite Codes used to pair Users into a Relationship
#-------------------------------------------------------------------------------
class InviteCode < ApplicationRecord
  belongs_to :relationship
  belongs_to :created_by_user, class_name: 'User'

  before_create :generate_code
  after_commit :broadcast_status_change, on: [:create, :update]

  CODE_CHARSET = (("A".."Z").to_a + ("1".."9").to_a).freeze

  def payload
    {
      code: code,
      expires_at: expires_at
    }
  end

  private

  def generate_code
    loop do
      self.code = 6.times.map { CODE_CHARSET[Sysrandom.random_number(CODE_CHARSET.length)] }.join
      break unless self.class.exists?(code: code)
    end
  end

  def broadcast_status_change
    relationship.broadcast_status_change
  end
end
