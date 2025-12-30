class ExtendUsersWithRoles < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :string, default: 'artfriend', null: false
    add_column :users, :name, :string
    add_column :users, :bio, :text

    add_index :users, :role
  end
end
