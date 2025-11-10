# frozen_string_literal: true

module Api
  module V1
    module Validate
      # No-op validator used as a default for controllers that don't
      # require request-specific validation.
      class Noop
        include ActiveModel::Validations

        def initialize(_params = {})
        end
      end
    end
  end
end


