# frozen_string_literal: true

module Api
  module Validate
    #-------------------------------------------------------------------------
    # Input Validation: Before Decoding
    #-------------------------------------------------------------------------
    class Data
      include ActiveModel::Validations

      attr_accessor :data

      BASE_64_REGEX = { with: %r{(?:[A-Za-z0-9+/\n]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=|[A-Za-z0-9+/\n]{4})} }.freeze

      validates :data, presence: true, format: BASE_64_REGEX

      def initialize(params = {})
        @data = params[:data]
      end
    end
  end
end
