# frozen_string_literal: true

module Api
  module V1
    class AnswersController < GenericController
      include ::UserAuthentication

      def initialize
        super(Validate::Answers::Update, Base64Decoder.new)
      end

      before_action :authenticate_user!
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

        render json: answer.payload
      end
    end
  end
end


