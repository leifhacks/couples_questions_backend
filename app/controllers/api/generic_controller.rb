# frozen_string_literal: true

module Api
  #---------------------------------------------------------------------------
  # A generic controller class which provides basic API functionalities like
  # a search query and convertion to json
  #---------------------------------------------------------------------------
  class GenericController < ApplicationController
    include ActionController::HttpAuthentication::Token::ControllerMethods
    wrap_parameters false
    before_action :restrict_access, :validate_data, :decode_params, :validate_with_validator

    ActionController::Parameters.action_on_unpermitted_parameters = :raise

    def initialize(validator, parser)
      super()
      @validator = validator
      @parser = parser
    end

    rescue_from(ActionController::UnpermittedParameters) do |pme|
      render json: { error: { unknown_parameters: pme.params } },
             status: :bad_request
    end

    def restrict_access
      authenticate_or_request_with_http_token do |token, _options|
        ApiKey.exists?(access_token: token)
      end
    end

    def validate_data
      validate_with_validator(Validate::Data)
    end

    def decode_params
      decoded_hash = @parser.call(params[:data])
      params.delete(:data)
      decoded_hash.each do |key, value|
        params[key] = value
      end

      Rails.logger.info("#{self.class}.#{__method__}: #{ParamsSanitizerService.new.sanitize(params)}")
    rescue JSON::ParserError, ArgumentError, TypeError
      render json: { error: 'invalid_data' }, status: :bad_request
    end

    def validate_with_validator(validator = @validator)
      activity = validator.new(params)
      return if activity.valid?

      render json: { error: activity.errors }, status: :unprocessable_entity
    end
  end
end
