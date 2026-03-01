class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string   :email,                null: false
      t.string   :name,                 null: false, limit: 50
      t.string   :password_digest,      null: false
      t.string   :remember_digest
      t.binary   :master_key_salt,      null: false
      t.binary   :encrypted_master_key, null: false
      t.datetime :last_login_at
      t.string   :last_login_ip,        limit: 45
      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
