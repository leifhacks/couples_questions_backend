# frozen_string_literal: true

module Api
  module V1
    module Validate
      #-------------------------------------------------------------------------
      # Image Input Validation
      #-------------------------------------------------------------------------
      class ImageVerification
        include ActiveModel::Validations

        attr_accessor :file_path

        validates :file_path, presence: true

        def initialize(params = {})
          @file_path = params[:file_path]

          @allowed_types = %i[file_path]
        end
      end
    end
  end
end
