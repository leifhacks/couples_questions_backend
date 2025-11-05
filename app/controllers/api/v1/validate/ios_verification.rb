# frozen_string_literal: true

module Api
  module V1
    module Validate
      #-------------------------------------------------------------------------
      # IOs Verification Input Validation
      #-------------------------------------------------------------------------
      class IosVerification
        include ActiveModel::Validations

        attr_accessor :receipt_data

        def initialize(params = {})
          @receipt_data = params[:receipt_data]

          @allowed_types = %i[receipt_data]
        end
      end
    end
  end
end
