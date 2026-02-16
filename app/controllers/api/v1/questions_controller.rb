# frozen_string_literal: true

module Api
  module V1
    class QuestionsController < GenericController
      include ::UserAuthentication

      def initialize
        super(Validate::Noop, Base64Decoder.new)
      end

      skip_before_action :validate_with_validator
      skip_before_action :validate_data, :decode_params, only: [:today_question, :latest_questions]
      before_action :authenticate_user!
      before_action :ensure_active_relationship!, only: [:today_question, :latest_questions, :journal]
      before_action -> { validate_with_validator(Validate::Questions::Journal) }, only: [:journal]

      # GET /api/v1/today_question, LEGACY
      def today_question
        relationship = current_user.current_relationship
        question_date = relationship.current_date_for(current_user)

        assignment = QuestionAssignment.find_by(relationship: relationship, question_date: question_date)
        assignment ||= question_assignment_service.assign_for_date!(relationship: relationship, date: question_date)

        render json: assignment.payload(viewer: current_user)
      end

      # GET /api/v1/latest_questions
      def latest_questions
        relationship = current_user.current_relationship
        question_date = relationship.current_date_for(current_user)
        yesterday_date = question_date - 1.day

        assignment = QuestionAssignment.find_by(relationship: relationship, question_date: question_date)
        assignment ||= question_assignment_service.assign_for_date!(relationship: relationship, date: question_date)

        yesterday_assignment = QuestionAssignment.find_by(relationship: relationship, question_date: yesterday_date)
        yesterday_assignment = nil if yesterday_assignment.present? && !yesterday_assignment.all_relationship_users_answered?

        render json: {
          today: assignment.payload(viewer: current_user),
          yesterday: yesterday_assignment&.payload(viewer: current_user)
        }
      end

      # GET /api/v1/journal?before=YYYY-MM-DD&limit=20
      def journal
        relationship = current_user.current_relationship
        current_question_date = relationship.current_date_for(current_user)
        before_date = parse_date_param(params[:before]) || current_question_date + 1.day
        limit = params[:limit].to_i
        limit = 20 if limit <= 0 || limit > 100

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

        payloads = assignments.limit(limit).map do |qa|
          qa.payload(viewer: current_user)
        end
        render json: payloads
      end

      private
      
      def ensure_active_relationship!
        relationship = current_user.current_relationship
        return render(json: { error: 'no_relationship' }, status: :not_found) if relationship.nil?
        return render(json: { error: 'relationship_ended' }, status: :bad_request) unless relationship.ACTIVE?
      end

      def question_assignment_service
        @question_assignment_service ||= QuestionAssignmentService.new(user: current_user)
      end

      def parse_date_param(value)
        return nil if value.blank?
        Date.parse(value) rescue nil
      end

    end
  end
end
