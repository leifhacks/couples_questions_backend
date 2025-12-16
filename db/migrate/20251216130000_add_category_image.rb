class AddCategoryImage < ActiveRecord::Migration[6.0]
  def change
    add_column :categories, :image_path, :string
  end
end
