class AddQuestionSegmentation < ActiveRecord::Migration[6.0]
  def change
    add_column :questions, :relationship_types, :text
    add_column :questions, :relationship_distances, :text
    add_column :questions, :extra_relevance_for_distances, :text
  end
end
