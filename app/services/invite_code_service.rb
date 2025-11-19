# frozen_string_literal: true

class InviteCodeService
  DEFAULT_TTL = 7.days

  def initialize(ttl: DEFAULT_TTL)
    @ttl = ttl
  end

  # Expires any currently active invites, then issues a new invite code.
  # Returns the created InviteCode.
  def issue!(relationship:, created_by_user:)
    ActiveRecord::Base.transaction do
      expire_active!(relationship: relationship)
      InviteCode.create!(relationship: relationship,
                         created_by_user: created_by_user,
                         expires_at: Time.current + @ttl)
    end
  end

  # Marks all active (unused and unexpired) invites as expired immediately.
  def expire_active!(relationship:)
    InviteCode.where(relationship: relationship, used_at: nil)
              .where('expires_at IS NULL OR expires_at > ?', Time.current)
              .update_all(expires_at: Time.current)
  end
end


