# frozen_string_literal: true

#-------------------------------------------------------------------------------
# Model for Question Categories
#-------------------------------------------------------------------------------
class Category < UuidRecord
  has_many :questions, dependent: :destroy

  def payload(lang)
    name = lang == 'de' ? name_de : name_en
    description = lang == 'de' ? description_de : description_en
    {
      uuid: uuid,
      name: name,
      description: description
    }
  end
end
