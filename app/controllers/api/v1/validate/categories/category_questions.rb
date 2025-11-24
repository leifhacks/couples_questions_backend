# frozen_string_literal: true

module Api
  module V1
    module Validate
      module Categories
        class CategoryQuestions
          include ActiveModel::Validations

          attr_accessor :uuid, :limit, :offset

          # Optional params used for pagination / filtering
          def initialize(params = {})
            @uuid = params[:uuid]
            @limit = params[:limit]
            @offset = params[:offset]
          end
        end
      end
    end
  end
end


