# frozen_string_literal: true

module Api
  module V1
    class QuestionsController < GenericController
      include ::UserAuthentication

      def initialize
        super(Validate::Noop, Base64Decoder.new)
      end

      skip_before_action :validate_with_validator
      skip_before_action :validate_data, :decode_params, only: [:today_question]
      before_action :authenticate_user!
      before_action :ensure_active_relationship!, only: [:today_question, :journal]
      before_action -> { validate_with_validator(Validate::Questions::Journal) }, only: [:journal]

      # GET /api/v1/today_question
      def today_question
        relationship = current_user.current_relationship
        question_date = relationship.current_date_for(current_user)

        assignment = QuestionAssignment.find_by(relationship: relationship, question_date: question_date)
        assignment ||= question_assignment_service.assign_for_date!(relationship: relationship, date: question_date)

        render json: assignment_payload(assignment, include_answers: true)
      end

      # GET /api/v1/journal?before=YYYY-MM-DD&limit=20
      def journal
        relationship = current_user.current_relationship
        before_date = parse_date_param(params[:before]) || relationship.current_date_for(current_user) + 1.day
        limit = params[:limit].to_i
        limit = 20 if limit <= 0 || limit > 100
        current_question_date = relationship.current_date_for(current_user)

        assignments = QuestionAssignment
                      .where(relationship: relationship)
                      .where('question_date < ?', before_date)
                      .left_joins(:answers)
                      .where(
                        'question_assignments.question_date = :current_date OR answers.user_id = :user_id',
                        current_date: current_question_date,
                        user_id: current_user.id
                      )
                      .distinct
                      .includes(:question, :answers)
                      .order(question_date: :desc)

        render json: assignments.limit(limit).map { |qa| assignment_payload(qa, include_answers: true) }
      end

      private
      
      def ensure_active_relationship!
        relationship = current_user.current_relationship
        return render(json: { error: 'no_relationship' }, status: :not_found) if relationship.nil?
        return render(json: { error: 'relationship_ended' }, status: :bad_request) unless relationship.ACTIVE?
      end

      def language_code_for(user)
        user.client_devices.order(updated_at: :desc).first&.language_code || 'en'
      end

      def question_assignment_service
        @question_assignment_service ||= QuestionAssignmentService.new(user: current_user)
      end

      def assignment_payload(assignment, include_answers:)
        lang = language_code_for(current_user)
        payload = assignment.payload(lang)
        return payload unless include_answers

        my_answer = assignment.answers.find { |a| a.user_id == current_user.id }
        partner_answer = assignment.answers.find { |a| a.user_id != current_user.id }

        # Withhold partner_answer until both have answered
        partner_visible = my_answer.present? && partner_answer.present?

        payload[:my_answer] = my_answer&.payload
        payload[:partner_answer] = partner_answer&.payload(include_body: partner_visible)

        payload
      end

      def parse_date_param(value)
        return nil if value.blank?
        Date.parse(value) rescue nil
      end
    end
  end
end
