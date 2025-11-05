# frozen_string_literal: true
require 'digest'

class TokenService
  def initialize(access_token_ttl: 15 * 60, refresh_token_ttl: 30 * 24 * 60 * 60, secret: Rails.application.secret_key_base)
    @access_token_ttl = access_token_ttl
    @refresh_token_ttl = refresh_token_ttl
    @secret = secret
  end

  def issue_access_token(user)
    payload = {
      sub: user.uuid,
      iat: Time.current.to_i,
      exp: (Time.current + @access_token_ttl).to_i
    }
    JWT.encode(payload, @secret, 'HS256')
  end

  def generate_refresh_token
    Sysrandom.hex(64)
  end

  def hash_refresh_token(token)
    Digest::SHA256.hexdigest(token)
  end

  def refresh_expires_at
    Time.current + @refresh_token_ttl
  end

  def access_expires_at
    Time.current + @access_token_ttl
  end

  def access_token_ttl
    @access_token_ttl
  end

  # Decodes and verifies an access token; returns payload hash or raises JWT errors
  def decode_access_token(token)
    JWT.decode(token, @secret, true, algorithm: 'HS256').first
  end

  # Returns the User for a valid access token, or nil if invalid/expired/not found
  def user_from_access_token(token)
    payload = decode_access_token(token)
    subject_uuid = payload['sub']
    return nil if subject_uuid.nil? || subject_uuid.empty?
    User.find_by(uuid: subject_uuid)
  rescue JWT::ExpiredSignature, JWT::DecodeError
    nil
  end
end


