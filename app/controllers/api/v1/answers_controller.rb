# frozen_string_literal: true

module Api
  module V1
    class AnswersController < GenericController
      include ::UserAuthentication

      def initialize
        super(Validate::Answers::Update, Base64Decoder.new)
      end

      before_action :authenticate_user!
      before_action :assign_current_initiator_device
      before_action -> { validate_with_validator(Validate::Answers::Update) }, only: [:update]

      # POST /api/v1/answers
      def update
        relationship = current_user.current_relationship
        return render(json: { error: 'no_relationship' }, status: :not_found) if relationship.nil?
        return render(json: { error: 'relationship_ended' }, status: :bad_request) unless relationship.ACTIVE?

        assignment_uuid = params[:question_assignment_uuid] || params.dig(:question_assignment, :uuid)
        answer_body = params[:body] || params.dig(:answer, :body)

        assignment = QuestionAssignment.find_by!(uuid: assignment_uuid)
        return render(json: { error: 'forbidden' }, status: :forbidden) unless assignment.relationship_id == relationship.id

        answer = Answer.find_or_initialize_by(question_assignment: assignment, user: current_user)
        answer.body = answer_body
        answer.save!

        partner_answer = assignment.answers.find { |a| a.user_id != current_user.id }

        render json: { my_answer: answer.payload, partner_answer: partner_answer&.payload }
      end

      def assign_current_initiator_device
        return unless defined?(Current)

        header_value = request.headers['X-Initiator-Device-Token']
        Current.initiator_device_token = header_value.presence
      end
    end
  end
end


