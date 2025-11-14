# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Helper for creating a fresh pending relationship for a single user
#-------------------------------------------------------------------------------
class RelationshipBootstrapService
  def initialize(invite_code_service: InviteCodeService.new)
    @invite_code_service = invite_code_service
  end

  # Creates a pending relationship for the provided user, sets the user as the
  # owner, issues a fresh invite code and assigns the relationship as the user's
  # current relationship. Returns [relationship, invite_code].
  def create_for_user!(user:, timezone_name: nil, timezone_offset_seconds: nil)
    raise ArgumentError, 'user must be present' if user.nil?

    ActiveRecord::Base.transaction do
      relationship = Relationship.create!(
        timezone_name: timezone_name,
        timezone_offset_seconds: timezone_offset_seconds
      )
      RelationshipMembership.create!(relationship: relationship, user: user, role: 'OWNER')
      invite = @invite_code_service.issue!(relationship: relationship, created_by_user: user)
      user.update!(current_relationship_id: relationship.id)
      [relationship, invite]
    end
  end
end


