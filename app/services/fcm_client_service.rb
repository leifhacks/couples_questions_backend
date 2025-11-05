# frozen_string_literal: true

#-------------------------------------------------------------------------------
# This class sends push messages via FCM
#-------------------------------------------------------------------------------
class FcmClientService
  def initialize(project = ENV['FIREBASE_PROJECT_NAME'], key_file_path = ENV['FIREBASE_KEY_FILE_PATH'])
    @project = project
    @key_file_path = key_file_path
    @access_token = generate_access_token
  end

  def send(token_batch, options)
    hydra = Typhoeus::Hydra.hydra

    requests = token_batch.map do |token|
      request = build_request(options, token)
      hydra.queue(request)

      [token, request]
    end

    hydra.run

    result = {}
    requests.each do |pair|
      result[pair[0]] = JSON.parse(pair[1].response.body)
    end

    result
  end

  def generate_access_token
    api_token = generate_api_token

    uri = URI('https://oauth2.googleapis.com/token')
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(uri.path)
    request['Content-Type'] = 'application/x-www-form-urlencoded'
    request.body = "grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=#{api_token}"
    response = https.request(request)
    json_response = JSON.parse(response.body)

    json_response['access_token']
  end

  private

  def build_request(options, token)
    Typhoeus::Request.new(
      "https://fcm.googleapis.com/v1/projects/#{@project}/messages:send",
      method: :post,
      body: JSON.generate({ message: options.merge(token: token) }),
      headers: { 'Authorization': "Bearer #{@access_token}", 'Content-Type': 'application/json' }
    )
  end

  def generate_api_token
    file = File.read(@key_file_path)
    json = JSON.parse(file)
    rsa_key = OpenSSL::PKey.read(json['private_key'])
    header = { "alg": 'RS256', "typ": 'JWT' }
    payload = {
      "iss": json['client_email'],
      "scope": 'https://www.googleapis.com/auth/firebase.messaging',
      "aud": json['token_uri'],
      "iat": DateTime.now.to_i,
      "exp": DateTime.now.to_i + 3600
    }

    JWT.encode payload, rsa_key, header[:alg], header
  end
end
