# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Model for Questions
#-------------------------------------------------------------------------------
class Question < UuidRecord
  belongs_to :category

  has_many :question_assignments, dependent: :destroy

  def payload(lang)
    { 
      uuid: uuid, 
      body: body(lang), 
      depth_level: depth_level, 
      category_uuid: category.uuid
    }
  end

  def body(lang)
    lang == 'de' ? body_de : body_en
  end
end
