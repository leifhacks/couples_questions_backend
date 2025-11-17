# frozen_string_literal: true

class AccessTokenFetcher
  HEADER_KEYS = %w[X-Access-Token X-User-Access-Token].freeze

  def initialize(request)
    @request = request
  end

  def call
    HEADER_KEYS.each do |key|
      token = normalized_token(@request.headers(key))
      return token if token.present?
    end
    nil
  end

  private

  def normalized_token(token)
    return nil if token.blank?

    token.start_with?('Bearer ') ? token.split(' ', 2)[1] : token
  end
end


