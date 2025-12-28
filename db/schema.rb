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

ActiveRecord::Schema[8.1].define(version: 2025_12_26_213828) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "favorites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "image_id", null: false
    t.integer "position"
    t.datetime "updated_at", null: false
    t.bigint "voting_session_id", null: false
    t.index ["image_id"], name: "index_favorites_on_image_id"
    t.index ["voting_session_id", "image_id"], name: "index_favorites_on_voting_session_id_and_image_id", unique: true
    t.index ["voting_session_id", "position"], name: "index_favorites_on_voting_session_id_and_position", unique: true
    t.index ["voting_session_id"], name: "index_favorites_on_voting_session_id"
  end

  create_table "images", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.float "elo_score", default: 1500.0, null: false
    t.integer "favorite_count", default: 0, null: false
    t.integer "position"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "vote_count", default: 0, null: false
    t.index ["elo_score"], name: "index_images_on_elo_score"
    t.index ["position"], name: "index_images_on_position"
  end

  create_table "invite_links", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "name"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.integer "vote_count", default: 0, null: false
    t.index ["token"], name: "index_invite_links_on_token", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "votes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "invite_link_id"
    t.bigint "loser_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "voting_session_id"
    t.bigint "winner_id", null: false
    t.index ["invite_link_id"], name: "index_votes_on_invite_link_id"
    t.index ["loser_id"], name: "index_votes_on_loser_id"
    t.index ["voting_session_id"], name: "index_votes_on_voting_session_id"
    t.index ["winner_id"], name: "index_votes_on_winner_id"
  end

  create_table "voting_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "last_activity"
    t.string "session_token", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["session_token"], name: "index_voting_sessions_on_session_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "favorites", "images"
  add_foreign_key "favorites", "voting_sessions"
  add_foreign_key "sessions", "users"
end
