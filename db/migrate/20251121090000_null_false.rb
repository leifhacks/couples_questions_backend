class NullFalse < ActiveRecord::Migration[6.0]
  def change
    change_column :client_devices, :platform, :string, null: false
    change_column :client_devices, :timezone_name, :string, null: false
    change_column :client_devices, :timezone_offset_seconds, :integer, null: false
    change_column :users, :name, :string, null: false
    change_column :relationship_memberships, :role, :string, null: false
    change_column :categories, :name_en, :string, null: false
    change_column :categories, :name_de, :string, null: false
    change_column :categories, :description_en, :text, null: false
    change_column :categories, :description_de, :text, null: false
    change_column :questions, :body_en, :text, null: false
    change_column :questions, :body_de, :text, null: false
    change_column :questions, :depth_level, :integer, null: false
    change_column :answers, :body, :text, null: false
  end
end
