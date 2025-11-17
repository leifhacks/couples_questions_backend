# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Model for Questions
#-------------------------------------------------------------------------------
class Question < UuidRecord
  belongs_to :category

  has_many :question_assignments, dependent: :destroy

  def brief_payload(lang)
    { uuid: uuid, question: body(lang) }
  end

  def body(lang)
    lang == 'de' ? body_de : body_en
  end
end
