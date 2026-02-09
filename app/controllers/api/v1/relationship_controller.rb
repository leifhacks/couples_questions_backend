# frozen_string_literal: true

module Api
  module V1
    class RelationshipController < GenericController
      include ::UserAuthentication

      def initialize
        super(Validate::Relationship::Update, Base64Decoder.new)
      end

      before_action :authenticate_user!
      skip_before_action :validate_data, :decode_params, only: [:show]
      before_action :assign_current_initiator_device
      before_action :ensure_active_or_pending_relationship!, only: [:show, :update, :new_invite]
      before_action -> { validate_with_validator(Validate::Relationship::Update) }, only: [:update]
      before_action -> { validate_with_validator(Validate::Relationship::ConfirmInvite) }, only: [:confirm_invite]
      before_action -> { validate_with_validator(Validate::Relationship::RedeemInvite) }, only: [:redeem_invite]

      # GET /api/v1/relationship
      def show
        relationship = current_user.current_relationship
        render json: relationship.extended_payload(current_user)
      end

      # POST /api/v1/relationship
      def update
        relationship = current_user.current_relationship
        relationship.update!(update_params) unless update_params.empty?
        render json: relationship.extended_payload(current_user)
      end

      # GET /api/v1/relationship/new_invite
      def new_invite
        relationship = current_user.current_relationship
        return render(json: { error: 'invalid_status' }, status: :bad_request) if relationship.ACTIVE?

        invite = @bootstrapped_relationship_invite ||
                 invite_code_service.issue!(relationship: relationship, created_by_user: current_user)
        render json: { invite_code: invite.payload }
      end

      # POST /api/v1/relationship/unpair
      def unpair
        relationship = current_user.current_relationship
        return render(json: { error: 'invalid_status' }, status: :bad_request) unless relationship&.ACTIVE?

        participants = relationship.users.to_a

        ActiveRecord::Base.transaction do
          relationship.update!(status: 'ENDED')
          relationship.relationship_memberships.includes(:user).find_each do |m|
            m.user.update!(current_relationship_id: nil)
          end
        end

        current_user_new_relationship = nil
        participants.uniq(&:id).each do |participant|
          relationship, = bootstrap_new_relationship_for(participant)
          current_user_new_relationship ||= relationship if participant.id == current_user.id
        end

        return render(json: { error: 'bootstrap_failed' }, status: :internal_server_error) if current_user_new_relationship.nil?

        render json: current_user_new_relationship.extended_payload(current_user)
      end

      # POST /api/v1/relationship/confirm_invite
      def confirm_invite
        relationship = current_user.current_relationship
        return render(json: { error: 'invalid_status' }, status: :bad_request) unless relationship&.PENDING?

        partner = relationship.users.find_by(uuid: params[:partner_uuid])
        return render(json: { error: 'partner_not_found' }, status: :not_found) if partner.nil?

        membership = RelationshipMembership.find_by(relationship: relationship, user: current_user)

        case params[:action_type]
        when 'APPROVE'
          approve_relationship(relationship, membership)
        when 'REJECT'
          reject_relationship(relationship, membership)
        else
          render json: { error: 'invalid_action' }, status: :bad_request
        end
      end

      # POST /api/v1/relationship/redeem_invite
      def redeem_invite
        code = InviteCode.find_by(code: params[:invite_code])
        return render(json: { error: 'invalid_code' }, status: :not_found) if code.nil?
        return render(json: { error: 'expired' }, status: :bad_request) if code.expires_at.present? && code.expires_at <= Time.current
        return render(json: { error: 'already_used' }, status: :bad_request) if code.used_at.present?

        relationship = code.relationship
        return render(json: { error: 'invalid_status' }, status: :bad_request) unless relationship.PENDING?
        return render(json: { error: 'already_member' }, status: :bad_request) if relationship.users.exists?(id: current_user.id)

        if relationship.users.count == 1
          ActiveRecord::Base.transaction do
            RelationshipMembership.create!(relationship: relationship, user: current_user, role: 'PARTNER')
            current_user.update!(current_relationship_id: relationship.id)
            relationship.users.reload.each { |u| u.update!(current_relationship_id: relationship.id) }
            code.update!(used_at: Time.current)
          end
          render json: relationship.extended_payload(current_user)
        else
          render json: { error: 'already_paired' }, status: :bad_request
        end
      end

      private

      def approve_relationship(relationship, membership)
        return render(json: { error: 'forbidden' }, status: :forbidden) unless membership&.OWNER?

        ActiveRecord::Base.transaction do
          relationship.update!(status: 'ACTIVE')
          transfer_previous_relationship_content!(relationship)
        end
        render json: relationship.extended_payload(current_user)
      end

      def reject_relationship(relationship, membership)
        return render(json: { error: 'forbidden' }, status: :forbidden) if membership.nil?

        partner = relationship.users.find_by(uuid: params[:partner_uuid])
        return render(json: { error: 'partner_not_found' }, status: :not_found) if partner.nil?

        owner_membership = membership&.OWNER?
        user_to_remove = owner_membership ? partner : current_user
        user_to_keep = owner_membership ? current_user : partner

        ActiveRecord::Base.transaction do
          user_to_remove.update!(current_relationship_id: nil)
          RelationshipMembership.where(relationship: relationship, user: user_to_remove).destroy_all
        end

        invite_code_service.issue!(relationship: relationship, created_by_user: user_to_keep)
        relationship = relationship.reload

        new_relationship, = bootstrap_new_relationship_for(user_to_remove)
        response_relationship = user_to_remove == current_user ? new_relationship : relationship

        render json: response_relationship.extended_payload(current_user)
      end

      def transfer_previous_relationship_content!(relationship)
        participant_ids = relationship.users.pluck(:id).uniq
        return unless participant_ids.size == 2

        relationship_ids_with_both = RelationshipMembership
                                     .where(user_id: participant_ids)
                                     .group(:relationship_id)
                                     .having('COUNT(DISTINCT user_id) = 2')
                                     .select(:relationship_id)

        previous = Relationship
                   .where(status: 'ENDED', id: relationship_ids_with_both)
                   .where.not(id: relationship.id)
                   .order(updated_at: :desc)
                   .first
        return if previous.nil?

        existing_dates = QuestionAssignment.where(relationship: relationship).pluck(:question_date)
        assignments = QuestionAssignment.where(relationship: previous)
        assignments = assignments.where.not(question_date: existing_dates) if existing_dates.any?
        assignments.update_all(relationship_id: relationship.id, updated_at: Time.current)
      end

      def ensure_active_or_pending_relationship!
        relationship = ensure_relationship_present!
        return render(json: { error: 'no_relationship' }, status: :not_found) if relationship.nil?
        return render(json: { error: 'relationship_ended' }, status: :bad_request) if relationship.ENDED?
      end

      def assign_current_initiator_device
        return unless defined?(Current)

        header_value = request.headers['X-Initiator-Device-Token']
        Current.initiator_device_token = header_value.presence
      end

      def update_params
        params.permit(:relationship_type, :distance)
      end

      def ensure_relationship_present!
        relationship = current_user.current_relationship
        return relationship if relationship.present?

        relationship, invite = bootstrap_new_relationship_for(current_user)
        @bootstrapped_relationship_invite = invite
        relationship
      end

      def bootstrap_new_relationship_for(user)
        timezone_name, timezone_offset = user.latest_timezone_components
        relationship, invite = relationship_bootstrap_service.create_for_user!(
          user: user,
          timezone_name: timezone_name,
          timezone_offset_seconds: timezone_offset
        )
        user.reload
        [relationship, invite]
      end

      def invite_code_service
        @invite_code_service ||= InviteCodeService.new
      end

      def relationship_bootstrap_service
        @relationship_bootstrap_service ||= RelationshipBootstrapService.new
      end
    end
  end
end


