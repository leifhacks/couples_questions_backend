# frozen_string_literal: true

module Api
  module V1
    module Validate
      module Answers
        class Update
          include ActiveModel::Validations

          attr_accessor :question_assignment_uuid, :body

          validates :question_assignment_uuid, presence: true
          validates :body, presence: true

          def initialize(params = {})
            @question_assignment_uuid = params[:question_assignment_uuid] || params.dig(:question_assignment, :uuid)
            @body = params[:body] || params.dig(:answer, :body)
          end
        end
      end
    end
  end
end


