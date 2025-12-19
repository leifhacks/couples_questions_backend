class AddQuestionSummary < ActiveRecord::Migration[6.0]
  def change
    add_column :questions, :summary_en, :text
    add_column :questions, :summary_de, :text
  end
end
