# frozen_string_literal: true

# Determines whether content should be blocked based on
# OpenAI moderation categories.
class ModerationService
  # Categories that should result in blocking when flagged by OpenAI
  BLOCKING_OPENAI_CATEGORIES = Set.new([
    'sexual',
    'sexual/minors',
    'self-harm/instructions',
    'hate/threatening',
    'harassment/threatening',
    'illicit',
    'illicit/violence',
    'sexual/violence',
  ]).freeze

  def initialize
    @service = OpenAiHydraService.new
  end

  # Calls the OpenAI moderation service
  def call(texts = [], image_file_names = [])
    results = @service.moderations(texts, image_file_names)
    results.select { |x| should_block?(x[1]) }.map{ |x| x[0] }
  end

  # Returns true if the content should be blocked based on inputs
  def should_block?(openai_categories)
    blocked_openai_categories(openai_categories).any?
  end

  # Returns a set of blocking categories that are present in the OpenAI result
  def blocked_openai_categories(openai_categories)
    category_keys = normalize_categories(openai_categories)
    category_keys & BLOCKING_OPENAI_CATEGORIES
  end

  def normalize_categories(categories)
    categories_hash = case categories
                      when String
                        begin
                          parsed = JSON.parse(categories.gsub("\"=>", "\":"))
                          parsed.is_a?(Hash) ? parsed : {}
                        rescue JSON::ParserError
                          {}
                        end
                      when Hash
                        categories
                      else
                        {}
                      end

    categories_hash.each_with_object(Set.new) do |(key, _value), set|
      set << key.to_s
    end
  end

end
