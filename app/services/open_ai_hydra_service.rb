# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Service class which calls the OpenAi API with Hydra and Typhoeus
#-------------------------------------------------------------------------------
class OpenAiHydraService
  def initialize
    @access_token = ENV['OPENAI_ACCESS_TOKEN']
    @organization_id = ENV['OPENAI_ORGANIZATION_ID']
  end

  def moderations(texts = [], image_file_names = [])
    hydra = Typhoeus::Hydra.hydra

    text_requests = texts.map do |text|
      request = build_text_request(text)
      hydra.queue(request)

      [text, request]
    end

    image_requests = image_file_names.map do |image_file_name|
      request = build_image_request(image_file_name)
      hydra.queue(request)

      [image_file_name, request]
    end

    hydra.run

    result = (text_requests + image_requests).map do |pair|
      begin
        response_body = pair[1].response.body
        raise "Empty response body" if response_body.nil? || response_body.empty?
        
        parsed_response = JSON.parse(response_body)
        categories = parsed_response.dig('results', 0, 'categories')
        
        raise "Invalid response structure: missing categories" if categories.nil?
        
        [pair[0], categories.reject { |_, value| !value }]
      rescue JSON::ParserError => e
        raise "Failed to parse OpenAI moderation response: '#{pair[0]}': #{response_body}, #{e.message}"
      rescue => e
        raise "OpenAI moderation processing failed for input '#{pair[0]}': #{response_body}, #{e.message}"
      end
    end

    result
  end

  private
  
  def build_text_request(text)
    Typhoeus::Request.new(
      "https://api.openai.com/v1/moderations",
      method: :post,
      body: JSON.generate(input: [{ "type": "text", "text": text }]),
      headers: get_headers
    )
  end

  def build_image_request(image_file_name)
    image_base64 = Base64.encode64(File.read(image_file_name)).delete("\n")

    Typhoeus::Request.new(
      "https://api.openai.com/v1/moderations",
      method: :post,
      body: JSON.generate(input: [{ "type": "image_url", "image_url": { "url": "data:image/webp;base64,#{image_base64}" } }]),
      headers: get_headers
    )
  end

  def get_headers
    { "Authorization" => "Bearer #{@access_token}", "OpenAI-Organization" => @organization_id, "Content-Type" => "application/json" }
  end
end
