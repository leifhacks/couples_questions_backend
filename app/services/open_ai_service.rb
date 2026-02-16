# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Service class which calls the OpenAi API
#-------------------------------------------------------------------------------
require 'base64'
require 'tempfile'

class OpenAiService
  def initialize
    OpenAI.configure do |config|
      config.access_token = ENV['OPENAI_ACCESS_TOKEN']
      config.organization_id = ENV['OPENAI_ORGANIZATION_ID']
    end
    @client = OpenAI::Client.new
  end

  def post_message(messages, functions, config)
    parameters = get_parameters(config, messages)
    parameters[:functions] = functions unless functions.empty?
    response = @client.chat(parameters: parameters)
    message = response.dig('choices', 0, 'message')

    if message['function_call'].nil?
      message['content']
    else
      JSON.parse(
        message.dig('function_call', 'arguments'),
        { symbolize_names: true }
      )
    end
  end

  def post_message_stream(messages, config, &on_response_callback)
    parameters = get_parameters(config, messages)
    parameters[:stream] = proc do |chunk, _bytesize|
      on_response_callback.call(chunk.dig('choices', 0, 'delta', 'content'))
    end
    @client.chat(parameters: parameters)
  end

  def generate_image(prompt, size: 1024, model: 'dall-e-3')
    parameters = {
      prompt: prompt,
      size: "#{size}x#{size}",
      n: 1,
      model: model
    }
    response = @client.images.generate(parameters: parameters)
    response.dig('data', 0, 'url')
  end

  def transcribe_audio(audio_data_url, model: 'gpt-4o-mini-transcribe')
    file_upload = build_audio_upload(audio_data_url)
    response = @client.audio.transcribe(
      parameters: {
        model: model,
        file: file_upload
      }
    )
    response['text']
  end

  private

  def get_parameters(config, messages)
    {
      model: config.model,
      messages: messages,
      max_tokens: config.max_tokens,
      temperature: config.temperature
    }
  end

  def build_audio_upload(audio_data_url)
    match = /\Adata:(?<mime>[^;]+);base64,(?<data>.+)\z/.match(audio_data_url)
    raise ArgumentError, 'invalid_audio_data_url' if match.nil?

    mime = match[:mime]
    extension = audio_extension_for(mime)
    raise ArgumentError, "unsupported_audio_mime: #{mime}" if extension.nil?

    decoded = Base64.decode64(match[:data])
    tempfile = Tempfile.new(["upload", extension])
    tempfile.binmode
    tempfile.write(decoded)
    tempfile.rewind

    Faraday::UploadIO.new(tempfile.path, mime, "audio#{extension}")
  end

  def audio_extension_for(mime)
    {
      'audio/m4a' => '.m4a',
      'audio/mp4' => '.mp4',
      'audio/mpeg' => '.mp3',
      'audio/wav' => '.wav',
      'audio/x-wav' => '.wav',
      'audio/webm' => '.webm',
      'audio/ogg' => '.ogg',
      'audio/opus' => '.opus'
    }[mime]
  end

end

#-------------------------------------------------------------------------------
# Config class for OpenAi requests
#-------------------------------------------------------------------------------
class OpenAiConfig
  attr_reader :temperature, :model, :max_tokens

  def initialize(temperature: 0.5, model: 'gpt-4o-mini', max_tokens: nil)
    @temperature = temperature
    @model = model
    @max_tokens = max_tokens
  end
end
