# frozen_string_literal: true

class AccessTokenFetcher
  HEADER_KEYS = %w[X-Access-Token X-User-Access-Token].freeze
  PARAM_KEY = 'access_token'.freeze

  def initialize(request)
    @request = request
  end

  def call
    from_header || from_params
  end

  private

  def from_header
    HEADER_KEYS.each do |key|
      token = normalized_token(@request.headers[key])
      return token if token.present?
    end
    nil
  end

  def from_params
    token = @request.params[PARAM_KEY]
    return token if token.present?
    nil
  end

  def normalized_token(token)
    return nil if token.blank?

    token.start_with?('Bearer ') ? token.split(' ', 2)[1] : token
  end
end


