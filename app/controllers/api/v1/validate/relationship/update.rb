# frozen_string_literal: true

module Api
  module V1
    module Validate
      module Relationship
        class Update
          include ActiveModel::Validations

          attr_accessor :relationship_type, :distance

          def initialize(params = {})
            @relationship_type = params[:relationship_type]
            @distance = params[:distance]
          end
        end
      end
    end
  end
end


