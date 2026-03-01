class CreateFolders < ActiveRecord::Migration[8.1]
  def change
    create_table :folders do |t|
      t.references :vault,  null: false, foreign_key: true
      t.string  :name,      null: false, limit: 100
      t.string  :icon,      limit: 50, default: "folder"
      t.integer :position,  null: false, default: 0
      t.integer :secrets_count, null: false, default: 0
      t.timestamps
    end

    add_index :folders, [ :vault_id, :name ], unique: true
  end
end
