# frozen_string_literal: true

module Api
  module V1
    class QuestionsController < GenericController
      include ::UserAuthentication

      def initialize
        super(Validate::Noop, Base64Decoder.new)
      end

      skip_before_action :validate_with_validator
      skip_before_action :validate_data, :decode_params, only: [:today_question, :journal]
      before_action :authenticate_user!
      before_action :ensure_active_relationship!, only: [:today_question, :journal]

      # GET /api/v1/today_question
      def today_question
        relationship = current_user.current_relationship
        question_date = current_date_in_relationship_tz(relationship)

        assignment = QuestionAssignment.find_by(relationship: relationship, question_date: question_date)
        assignment ||= assign_question_for_date!(relationship, question_date)

        render json: assignment_payload(assignment, include_answers: true)
      end

      # GET /api/v1/journal?before=YYYY-MM-DD&limit=20
      def journal
        relationship = current_user.current_relationship
        before_date = parse_date_param(params[:before]) || current_date_in_relationship_tz(relationship) + 1.day
        limit = params[:limit].to_i
        limit = 20 if limit <= 0 || limit > 100

        assignments = QuestionAssignment
                      .where(relationship: relationship)
                      .where('question_date < ?', before_date)
                      .joins(:answers)
                      .where(answers: { user_id: current_user.id })
                      .includes(:question, :answers)
                      .order(question_date: :desc)
                      .distinct

        render json: assignments.first(limit).map { |qa| assignment_payload(qa, include_answers: true) }
      end

      private

      def ensure_active_relationship!
        relationship = current_user.current_relationship
        return render(json: { error: 'no_relationship' }, status: :not_found) if relationship.nil?
        return render(json: { error: 'relationship_ended' }, status: :bad_request) unless relationship.ACTIVE?
      end

      def current_date_in_relationship_tz(relationship)
        offset = relationship&.timezone_offset_seconds || latest_device_offset_for(current_user) || 0
        (Time.now.utc + offset.to_i).to_date
      end

      def latest_device_offset_for(user)
        user.client_devices.order(updated_at: :desc).limit(1).pick(:timezone_offset_seconds)
      end

      def language_code_for(user)
        user.client_devices.order(updated_at: :desc).first&.language_code || 'en'
      end

      def assign_question_for_date!(relationship, date)
        base_scope = Question.where(is_active: true)

        my_fav = current_user.favorite_category_id
        partner = relationship.users.where.not(id: current_user.id).first
        partner_fav = partner&.favorite_category_id

        chosen_category_id = nil
        roll = rand

        if my_fav.present? && partner_fav.present?
          if my_fav == partner_fav
            # Same favorite: 50% favorite, 50% random
            chosen_category_id = my_fav if roll < 0.5
          else
            # Different favorites: 20% my fav, 20% partner fav, 60% random
            if roll < 0.2
              chosen_category_id = my_fav
            elsif roll < 0.4
              chosen_category_id = partner_fav
            end
          end
        elsif my_fav.present? || partner_fav.present?
          # One favorite present: 20% that favorite, 80% random
          single_fav = my_fav || partner_fav
          chosen_category_id = single_fav if roll < 0.2
        else
          # No favorites: 100% random across all categories
          chosen_category_id = nil
        end

        scoped = chosen_category_id.present? ? base_scope.where(category_id: chosen_category_id) : base_scope
        question = scoped.order(Arel.sql('RAND()')).first || base_scope.order(Arel.sql('RAND()')).first
        QuestionAssignment.create!(relationship: relationship, question: question, question_date: date)
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
