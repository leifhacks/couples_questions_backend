# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Service class which calls the OpenAi API
#-------------------------------------------------------------------------------
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

  private

  def get_parameters(config, messages)
    {
      model: config.model,
      messages: messages,
      max_tokens: config.max_tokens,
      temperature: config.temperature
    }
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
