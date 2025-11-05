# frozen_string_literal: true

module Api
  module V1
    module Validate
      module Relationship
        class ConfirmInvite
          include ActiveModel::Validations

          attr_accessor :action_type, :partner_uuid

          validates :action_type, inclusion: { in: %w[APPROVE REJECT] }
          validates :partner_uuid, presence: true

          def initialize(params = {})
            @action_type = params[:action_type]
            @partner_uuid = params[:partner_uuid]
          end
        end
      end
    end
  end
end


