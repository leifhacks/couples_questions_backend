# frozen_string_literal: true

module Api
  module V1
    module Validate
      module Relationship
        class Update
          include ActiveModel::Validations

          attr_accessor :relationship_type, :distance

          SAFE_STR_REGEX = /\A[A-Z_]+\z/

          validates :relationship_type, format: { with: SAFE_STR_REGEX }, allow_nil: true
          validates :distance, format: { with: SAFE_STR_REGEX }, allow_nil: true

          def initialize(params = {})
            @relationship_type = params[:relationship_type]
            @distance = params[:distance]
          end
        end
      end
    end
  end
end


