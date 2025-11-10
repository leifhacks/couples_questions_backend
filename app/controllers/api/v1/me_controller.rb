# frozen_string_literal: true

module Api
  module V1
    class MeController < GenericController
      include ::UserAuthentication
      def initialize
        super(Validate::Me::Update, Base64Decoder.new)
      end

      skip_before_action :validate_with_validator
      skip_before_action :validate_data, :decode_params, only: [:show]
      before_action :authenticate_user!
      before_action -> { validate_with_validator(Validate::Me::Update) }, only: [:update]

      # GET /api/v1/me
      def show
        render json: me_payload(current_user)
      end

      # PUT /api/v1/me
      def update
        ActiveRecord::Base.transaction do
          update_attrs = {}

          if params.key?(:name)
            update_attrs[:name] = params[:name]
          end

          if params.key?(:image_path)
            update_attrs[:image_path] = params[:image_path]
          end

          if params.key?(:favorite_category_uuid)
            if params[:favorite_category_uuid].present?
              category = Category.find_by!(uuid: params[:favorite_category_uuid])
              update_attrs[:favorite_category] = category
            else
              update_attrs[:favorite_category] = nil
            end
          end

          current_user.update!(update_attrs) unless update_attrs.empty?
        end

        render json: me_payload(current_user)
      end

      private

      def me_payload(user)
        {
          uuid: user.uuid,
          name: user.name,
          favorite_category_uuid: user.favorite_category&.uuid,
          image_path: user.image_path,
          current_relationship_uuid: user.current_relationship&.uuid
        }
      end

      # auth methods are provided by UserAuthentication concern
    end
  end
end


