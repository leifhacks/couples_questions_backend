# frozen_string_literal: true

module Api
  module V1
    module Validate
      module Questions
        class Journal
          include ActiveModel::Validations

          attr_accessor :before, :limit

          # Optional params used for pagination / filtering
          def initialize(params = {})
            @before = params[:before]
            @limit = params[:limit]
          end
        end
      end
    end
  end
end


