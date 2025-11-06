# frozen_string_literal: true

module Api
  module V1
    module Validate
      module Auth
        class Refresh
          include ActiveModel::Validations

          attr_accessor :refresh_token

          validates :refresh_token, presence: true

          def initialize(params = {})
            @refresh_token = params[:refresh_token]
          end
        end
      end
    end
  end
end



