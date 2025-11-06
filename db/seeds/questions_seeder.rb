# frozen_string_literal: true

require 'json'
require 'securerandom'

SEED_PATH = Rails.root.join('db', 'seeds', 'questions')

puts "== Importing categories and questions from #{SEED_PATH} =="

Dir.glob(SEED_PATH.join('*.json')).each do |file_path|
  data = JSON.parse(File.read(file_path))
  name_en = data['name_en']
  name_de = data['name_de']
  desc_en = data['description_en']
  desc_de = data['description_de']

  category = Category.find_or_initialize_by(name_en: name_en)
  category.name_de = name_de
  category.description_en = desc_en
  category.description_de = desc_de
  category.save!

  puts "→ Imported category: #{category.name_en}"

  data['questions'].each_with_index do |q, index|
    body_en = q['body_en']
    body_de = q['body_de']
    depth = q['depth']

    question = Question.find_or_initialize_by(body_en: body_en, category_id: category.id)
    question.body_de = body_de
    question.depth_level = depth
    question.is_active = true
    question.save!
  end

  puts "   Added #{data['questions'].size} questions."
end

puts "✅ Import finished!"
