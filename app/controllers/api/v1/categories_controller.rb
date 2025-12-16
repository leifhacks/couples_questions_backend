# frozen_string_literal: true

module Api
  module V1
    class CategoriesController < GenericController
      include ::UserAuthentication

      def initialize
        super(Validate::Noop, Base64Decoder.new)
      end

      skip_before_action :validate_with_validator
      skip_before_action :validate_data, :decode_params, only: [:index]
      before_action :authenticate_user!
      before_action -> { validate_with_validator(Validate::Categories::CategoryQuestions) }, only: [:category_questions]

      # GET /api/v1/categories
      def index
        lang = language_code_for(current_user)
        render json: Category.all.reverse.map { |c| c.payload(lang) }
      end

      # GET /api/v1/categories/:uuid/questions
      def category_questions
        category = Category.find_by!(uuid: params[:uuid])
        lang = language_code_for(current_user)

        limit = params[:limit].to_i
        offset = params[:offset].to_i
        limit = 20 if limit <= 0 || limit > 100
        offset = 0 if offset.negative?

        scope = category.questions.where(is_active: true)
        questions = scope.order(created_at: :desc).offset(offset).limit(limit)

        render json: questions.map { |q| q.payload(lang) }
      end

      private

      def language_code_for(user)
        user.client_devices.order(updated_at: :desc).first&.language_code || 'en'
      end
    end
  end
end
