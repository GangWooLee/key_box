class CreateAuditEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_events do |t|
      t.references :user,   null: false, foreign_key: true
      t.references :vault,  null: false, foreign_key: true
      t.references :secret, foreign_key: true
      t.string  :action,     null: false, limit: 50
      t.string  :ip_address, limit: 45
      t.string  :user_agent, limit: 500
      t.json    :metadata
      t.datetime :created_at, null: false
    end

    add_index :audit_events, :action
    add_index :audit_events, :created_at
  end
end
