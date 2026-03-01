class CreateSecrets < ActiveRecord::Migration[8.1]
  def change
    create_table :secrets do |t|
      t.references :folder, null: false, foreign_key: true
      t.references :vault,  null: false, foreign_key: true
      t.string  :name,      null: false, limit: 200
      t.binary  :encrypted_value,          null: false
      t.binary  :encrypted_value_iv,       null: false
      t.binary  :encrypted_value_auth_tag, null: false
      t.text    :notes,          limit: 2000
      t.string  :tags,           limit: 500
      t.string  :secret_type,    null: false, default: "api_key"
      t.string  :service_name,   limit: 100
      t.string  :environment,    limit: 50
      t.datetime :last_accessed_at
      t.integer  :access_count,  null: false, default: 0
      t.timestamps
    end

    add_index :secrets, [ :vault_id, :name ]
    add_index :secrets, :tags
    add_index :secrets, :service_name
    add_index :secrets, :secret_type
  end
end
