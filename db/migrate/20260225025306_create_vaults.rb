class CreateVaults < ActiveRecord::Migration[8.1]
  def change
    create_table :vaults do |t|
      t.string  :name,        null: false, limit: 100
      t.string  :description, limit: 500
      t.integer :vault_type,  null: false, default: 0
      t.timestamps
    end
  end
end
