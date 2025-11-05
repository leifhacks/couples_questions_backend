#-------------------------------------------------------------------------------
# This service class verifies a given id token and returns the corresponding uuid
#-------------------------------------------------------------------------------
class FirebaseTokenVerifier
  def call(id_token)
    validate_token(id_token)
  rescue => e
    Rails.logger.info("#{self.class}.#{__method__}: Invalid token #{e.message}")
    return nil
  end

  private

  def validate_token(id_token)
    decoded_token = JWT.decode(id_token, nil, false)
    payload = decoded_token.first
    headers = decoded_token.last

    return if headers['alg'] != 'RS256'
    return if headers['typ'] != 'JWT'
    return if payload['exp'].to_i < DateTime.now.to_i
    return if payload['iat'].to_i > DateTime.now.to_i
    return if payload['auth_time'].to_i > DateTime.now.to_i
    return if payload['aud'] != ENV['FIREBASE_PROJECT_NAME']
    return if payload['iss'] != "https://securetoken.google.com/#{payload['aud']}"
    return if payload['sub'].nil?

    uri = URI('https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com')
    keys = JSON.parse(Net::HTTP.get(uri))
    return unless keys.keys.include?(headers['kid'])

    certificate = OpenSSL::X509::Certificate.new(keys[headers['kid']])
    JWT.decode(id_token, certificate.public_key, true, algorithm: headers['alg'])

    [payload['sub'], payload['aud']]
  end
end
