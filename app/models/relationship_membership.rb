# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Join model between User and Relationship
#-------------------------------------------------------------------------------
class RelationshipMembership < ApplicationRecord
  enum role: { OWNER: 'OWNER', PARTNER: 'PARTNER' }

  belongs_to :relationship
  belongs_to :user

  after_commit :recalculate_relationship_timezone
  after_commit :broadcast_member_added, on: :create
  after_commit :broadcast_member_removed, on: :destroy

  private

  def recalculate_relationship_timezone
    relationship&.recalculate_timezone!
  end

  def broadcast_member_added
    Rails.logger.info("broadcast_member_added Broadcasting membership change to users: #{user&.name}")
    relationship&.broadcast_membership_change!(user: user)
  end

  def broadcast_member_removed
    Rails.logger.info("broadcast_member_removed Broadcasting membership change to users: #{user&.name}")
    relationship&.broadcast_membership_change!(user: user)
  end
end


