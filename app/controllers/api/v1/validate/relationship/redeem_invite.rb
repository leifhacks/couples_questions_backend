# frozen_string_literal: true

module Api
  module V1
    module Validate
      module Relationship
        class RedeemInvite
          include ActiveModel::Validations

          attr_accessor :invite_code

          validates :invite_code, presence: true

          def initialize(params = {})
            @invite_code = params[:invite_code]
          end
        end
      end
    end
  end
end


