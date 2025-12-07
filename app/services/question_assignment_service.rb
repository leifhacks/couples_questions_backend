# frozen_string_literal: true

require 'json'

#-------------------------------------------------------------------------------
# Service class which assigns a question for a given relationship and date
#-------------------------------------------------------------------------------
class QuestionAssignmentService
  def initialize(user:)
    @user = user
  end

  # Assigns a question for the given relationship and date, taking into
  # account both users' favorite categories, relationship segmentation
  # (type/distance), and avoiding recent repeats.
  # Returns the created QuestionAssignment.
  def assign_for_date!(relationship:, date:)
    base_scope = Question.where(is_active: true)
    scoped = scope_for_relationship(base_scope, relationship)

    # Apply relationship type/distance segmentation in Ruby
    scoped_questions = segmented_questions(scoped, relationship)
    global_questions = nil

    # Avoid repeating questions from the last 90 days for this relationship if possible
    recent_question_ids = QuestionAssignment
                          .where(relationship: relationship)
                          .where('question_date >= ?', date - 90.days)
                          .pluck(:question_id)

    primary_candidates =
      if recent_question_ids.any?
        scoped_questions.reject { |q| recent_question_ids.include?(q.id) }
      else
        scoped_questions
      end

    question = weighted_sample(primary_candidates, relationship)

    # If none available in the chosen scope, try globally excluding recent questions
    if question.nil? && recent_question_ids.any?
      global_questions ||= segmented_questions(base_scope, relationship)
      global_primary_candidates = global_questions.reject { |q| recent_question_ids.include?(q.id) }
      question = weighted_sample(global_primary_candidates, relationship)
    end

    # As a final fallback, allow repeats (including within 90 days) to ensure we always have a question
    question ||= weighted_sample(scoped_questions, relationship)
    if question.nil?
      global_questions ||= segmented_questions(base_scope, relationship)
      question = weighted_sample(global_questions, relationship)
    end

    # Absolute last resort: fall back to old SQL-based random selection so we never break.
    question ||= scoped.order(Arel.sql('RAND()')).first
    question ||= base_scope.order(Arel.sql('RAND()')).first

    QuestionAssignment.create!(relationship: relationship, question: question, question_date: date)
  end

  private

  def scope_for_relationship(base_scope, relationship)
    chosen_category_id = determine_chosen_category_id(relationship)
    chosen_category_id.present? ? base_scope.where(category_id: chosen_category_id) : base_scope
  end

  # Returns an array of questions that match the relationship's type/distance
  # segmentation rules.
  def segmented_questions(scope, relationship)
    rel_type = relationship.relationship_type
    rel_distance = relationship.distance

    scope.to_a.select do |question|
      matches_type = types_match?(question.relationship_types, rel_type)
      matches_distance = distances_match?(question.relationship_distances, rel_distance)
      matches_type && matches_distance
    end
  end

  def types_match?(raw_types, rel_type)
    return true if rel_type.blank? || raw_types.blank?

    types = parse_array_field(raw_types)
    return true if types.empty?

    types.include?(rel_type)
  end

  def distances_match?(raw_distances, rel_distance)
    return true if rel_distance.blank? || raw_distances.blank?

    distances = parse_array_field(raw_distances)
    return true if distances.empty?

    distances.include?(rel_distance)
  end

  # Randomly picks a question, giving extra weight to questions that have
  # extra_relevance_for_distances containing the relationship's distance.
  def weighted_sample(questions, relationship)
    return nil if questions.blank?

    rel_distance = relationship.distance

    weighted = questions.map do |q|
      weight = 1
      extras = parse_array_field(q.extra_relevance_for_distances)
      weight += 2 if rel_distance.present? && extras.include?(rel_distance)
      [q, weight]
    end

    total_weight = weighted.sum { |(_, w)| w }
    target = rand * total_weight
    running = 0.0

    weighted.each do |question, weight|
      running += weight
      return question if target <= running
    end

    weighted.last.first
  end

  # Parses a Text column that stores an array-like value.
  # Supports:
  # - Ruby Array objects (when AR gives them back directly)
  # - JSON / Array#to_s strings like '["A","B"]'
  # - Comma separated strings like 'A,B'
  def parse_array_field(raw)
    case raw
    when Array
      raw.map(&:to_s)
    when String
      value = raw.strip
      return [] if value.empty?

      begin
        parsed = JSON.parse(value)
        return parsed.is_a?(Array) ? parsed.map(&:to_s) : []
      rescue JSON::ParserError
        # Fallback: naive comma split, stripping brackets/quotes
        value.tr('[]', '').split(',').map { |s| s.strip.delete('"') }.reject(&:empty?)
      end
    else
      []
    end
  end

  def determine_chosen_category_id(relationship)
    my_fav = user.favorite_category_id
    partner = relationship.users.where.not(id: user.id).first
    partner_fav = partner&.favorite_category_id

    roll = rand

    if my_fav.present? && partner_fav.present?
      if my_fav == partner_fav
        # Same favorite: 50% favorite, 50% random
        return my_fav if roll < 0.5
      else
        # Different favorites: 20% my fav, 20% partner fav, 60% random
        if roll < 0.2
          return my_fav
        elsif roll < 0.4
          return partner_fav
        end
      end
    elsif my_fav.present? || partner_fav.present?
      # One favorite present: 20% that favorite, 80% random
      single_fav = my_fav || partner_fav
      return single_fav if roll < 0.2
    else
      # No favorites: 100% random across all categories
      return nil
    end
  end

  attr_reader :user
end
