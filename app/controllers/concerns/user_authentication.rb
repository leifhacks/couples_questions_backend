# frozen_string_literal: true

module UserAuthentication
  extend ActiveSupport::Concern

  included do
    before_action :reset_current_user
  end

  private

  def authenticate_user!
    token = AccessTokenFetcher.new(request).call
    return render(json: { error: 'unauthorized' }, status: :unauthorized) if token.blank?
    user = token_service.user_from_access_token(token)
    return render(json: { error: 'unauthorized' }, status: :unauthorized) if user.nil?
    @current_user = user
  end

  def current_user
    @current_user
  end

  def reset_current_user
    @current_user = nil
  end

  def token_service
    @token_service ||= TokenService.new
  end
end
