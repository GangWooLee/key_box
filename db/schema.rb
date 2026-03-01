# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_25_025310) do
  create_table "audit_events", force: :cascade do |t|
    t.string "action", limit: 50, null: false
    t.datetime "created_at", null: false
    t.string "ip_address", limit: 45
    t.json "metadata"
    t.integer "secret_id"
    t.string "user_agent", limit: 500
    t.integer "user_id", null: false
    t.integer "vault_id", null: false
    t.index ["action"], name: "index_audit_events_on_action"
    t.index ["created_at"], name: "index_audit_events_on_created_at"
    t.index ["secret_id"], name: "index_audit_events_on_secret_id"
    t.index ["user_id"], name: "index_audit_events_on_user_id"
    t.index ["vault_id"], name: "index_audit_events_on_vault_id"
  end

  create_table "folders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "icon", limit: 50, default: "folder"
    t.string "name", limit: 100, null: false
    t.integer "position", default: 0, null: false
    t.integer "secrets_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "vault_id", null: false
    t.index ["vault_id", "name"], name: "index_folders_on_vault_id_and_name", unique: true
    t.index ["vault_id"], name: "index_folders_on_vault_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "vault_id", null: false
    t.index ["user_id", "vault_id"], name: "index_memberships_on_user_id_and_vault_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
    t.index ["vault_id"], name: "index_memberships_on_vault_id"
  end

  create_table "secrets", force: :cascade do |t|
    t.integer "access_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.binary "encrypted_value", null: false
    t.binary "encrypted_value_auth_tag", null: false
    t.binary "encrypted_value_iv", null: false
    t.string "environment", limit: 50
    t.integer "folder_id", null: false
    t.datetime "last_accessed_at"
    t.string "name", limit: 200, null: false
    t.text "notes", limit: 2000
    t.string "secret_type", default: "api_key", null: false
    t.string "service_name", limit: 100
    t.string "tags", limit: 500
    t.datetime "updated_at", null: false
    t.integer "vault_id", null: false
    t.index ["folder_id"], name: "index_secrets_on_folder_id"
    t.index ["secret_type"], name: "index_secrets_on_secret_type"
    t.index ["service_name"], name: "index_secrets_on_service_name"
    t.index ["tags"], name: "index_secrets_on_tags"
    t.index ["vault_id", "name"], name: "index_secrets_on_vault_id_and_name"
    t.index ["vault_id"], name: "index_secrets_on_vault_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.binary "encrypted_master_key", null: false
    t.datetime "last_login_at"
    t.string "last_login_ip", limit: 45
    t.binary "master_key_salt", null: false
    t.string "name", limit: 50, null: false
    t.string "password_digest", null: false
    t.string "remember_digest"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "vaults", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description", limit: 500
    t.string "name", limit: 100, null: false
    t.datetime "updated_at", null: false
    t.integer "vault_type", default: 0, null: false
  end

  add_foreign_key "audit_events", "secrets"
  add_foreign_key "audit_events", "users"
  add_foreign_key "audit_events", "vaults"
  add_foreign_key "folders", "vaults"
  add_foreign_key "memberships", "users"
  add_foreign_key "memberships", "vaults"
  add_foreign_key "secrets", "folders"
  add_foreign_key "secrets", "vaults"
end
