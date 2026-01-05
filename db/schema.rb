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

ActiveRecord::Schema[8.1].define(version: 2026_01_05_131935) do
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

  create_table "artists", force: :cascade do |t|
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "instagram_handle"
    t.string "name", null: false
    t.string "twitter_handle"
    t.datetime "updated_at", null: false
    t.string "website_url"
    t.index ["name"], name: "index_artists_on_name"
  end

  create_table "artworks", force: :cascade do |t|
    t.bigint "artist_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.float "elo_score", default: 1500.0, null: false
    t.bigint "exhibition_id"
    t.integer "favorite_count", default: 0, null: false
    t.string "medium"
    t.integer "position"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "vote_count", default: 0, null: false
    t.integer "year"
    t.index ["artist_id"], name: "index_artworks_on_artist_id"
    t.index ["elo_score"], name: "index_artworks_on_elo_score"
    t.index ["exhibition_id"], name: "index_artworks_on_exhibition_id"
    t.index ["position"], name: "index_artworks_on_position"
  end

  create_table "check_ins", force: :cascade do |t|
    t.string "action_type", null: false
    t.bigint "checkable_id", null: false
    t.string "checkable_type", null: false
    t.datetime "created_at", null: false
    t.bigint "exhibition_id"
    t.string "ip_address"
    t.jsonb "metadata"
    t.bigint "screen_id"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id"
    t.bigint "voting_session_id"
    t.index ["action_type"], name: "index_check_ins_on_action_type"
    t.index ["checkable_type", "checkable_id"], name: "index_check_ins_on_checkable"
    t.index ["checkable_type", "checkable_id"], name: "index_check_ins_on_checkable_type_and_checkable_id"
    t.index ["created_at"], name: "index_check_ins_on_created_at"
    t.index ["exhibition_id"], name: "index_check_ins_on_exhibition_id"
    t.index ["screen_id"], name: "index_check_ins_on_screen_id"
    t.index ["user_id"], name: "index_check_ins_on_user_id"
    t.index ["voting_session_id"], name: "index_check_ins_on_voting_session_id"
  end

  create_table "comparisons", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "exhibition_id"
    t.bigint "invite_link_id"
    t.bigint "losing_artwork_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.bigint "voting_session_id"
    t.bigint "winning_artwork_id", null: false
    t.index ["exhibition_id"], name: "index_comparisons_on_exhibition_id"
    t.index ["invite_link_id"], name: "index_comparisons_on_invite_link_id"
    t.index ["losing_artwork_id"], name: "index_comparisons_on_losing_artwork_id"
    t.index ["user_id"], name: "index_comparisons_on_user_id"
    t.index ["voting_session_id"], name: "index_comparisons_on_voting_session_id"
    t.index ["winning_artwork_id"], name: "index_comparisons_on_winning_artwork_id"
  end

  create_table "exhibition_media", force: :cascade do |t|
    t.text "caption"
    t.datetime "created_at", null: false
    t.bigint "exhibition_id", null: false
    t.string "photographer"
    t.integer "position"
    t.datetime "updated_at", null: false
    t.index ["exhibition_id"], name: "index_exhibition_media_on_exhibition_id"
  end

  create_table "exhibitions", force: :cascade do |t|
    t.integer "artwork_count", default: 0
    t.integer "comparison_count", default: 0
    t.datetime "created_at", null: false
    t.text "description"
    t.date "end_date"
    t.string "luma_url"
    t.string "manifold_url"
    t.integer "number"
    t.string "poap_url"
    t.string "slug", null: false
    t.bigint "space_id", null: false
    t.date "start_date"
    t.string "status", default: "upcoming", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["number"], name: "index_exhibitions_on_number", unique: true
    t.index ["slug"], name: "index_exhibitions_on_slug", unique: true
    t.index ["space_id"], name: "index_exhibitions_on_space_id"
    t.index ["status"], name: "index_exhibitions_on_status"
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

  create_table "preferences", force: :cascade do |t|
    t.bigint "artwork_id", null: false
    t.datetime "created_at", null: false
    t.bigint "exhibition_id"
    t.integer "position"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.bigint "voting_session_id", null: false
    t.index ["artwork_id"], name: "index_preferences_on_artwork_id"
    t.index ["exhibition_id"], name: "index_preferences_on_exhibition_id"
    t.index ["user_id"], name: "index_preferences_on_user_id"
    t.index ["voting_session_id", "artwork_id"], name: "index_preferences_on_voting_session_id_and_artwork_id", unique: true
    t.index ["voting_session_id", "position"], name: "index_preferences_on_voting_session_id_and_position", unique: true
    t.index ["voting_session_id"], name: "index_preferences_on_voting_session_id"
  end

  create_table "screens", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.bigint "exhibition_id"
    t.string "location_description"
    t.string "name", null: false
    t.string "screen_number"
    t.bigint "space_id", null: false
    t.datetime "updated_at", null: false
    t.index ["exhibition_id"], name: "index_screens_on_exhibition_id"
    t.index ["space_id", "screen_number"], name: "index_screens_on_space_id_and_screen_number", unique: true
    t.index ["space_id"], name: "index_screens_on_space_id"
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
    t.bigint "exhibition_id"
    t.string "key", null: false
    t.string "setting_type", default: "global"
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["exhibition_id"], name: "index_settings_on_exhibition_id"
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "spaces", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "location"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.string "website_url"
  end

  create_table "users", force: :cascade do |t|
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name"
    t.string "password_digest", null: false
    t.string "role", default: "artfriend", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  create_table "voting_session_artwork_scores", force: :cascade do |t|
    t.bigint "artwork_id", null: false
    t.datetime "created_at", null: false
    t.bigint "exhibition_id", null: false
    t.decimal "personal_elo_score", precision: 10, scale: 2, default: "1500.0", null: false
    t.datetime "updated_at", null: false
    t.integer "vote_count", default: 0, null: false
    t.bigint "voting_session_id", null: false
    t.index ["artwork_id"], name: "index_voting_session_artwork_scores_on_artwork_id"
    t.index ["exhibition_id"], name: "index_voting_session_artwork_scores_on_exhibition_id"
    t.index ["voting_session_id", "artwork_id"], name: "index_vs_artwork_scores_on_session_and_artwork", unique: true
    t.index ["voting_session_id"], name: "index_voting_session_artwork_scores_on_voting_session_id"
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
  add_foreign_key "artworks", "artists"
  add_foreign_key "artworks", "exhibitions"
  add_foreign_key "check_ins", "exhibitions"
  add_foreign_key "check_ins", "screens"
  add_foreign_key "check_ins", "users"
  add_foreign_key "check_ins", "voting_sessions"
  add_foreign_key "comparisons", "exhibitions"
  add_foreign_key "comparisons", "users"
  add_foreign_key "exhibition_media", "exhibitions"
  add_foreign_key "exhibitions", "spaces"
  add_foreign_key "preferences", "artworks"
  add_foreign_key "preferences", "exhibitions"
  add_foreign_key "preferences", "users"
  add_foreign_key "preferences", "voting_sessions"
  add_foreign_key "screens", "exhibitions"
  add_foreign_key "screens", "spaces"
  add_foreign_key "sessions", "users"
  add_foreign_key "settings", "exhibitions"
  add_foreign_key "voting_session_artwork_scores", "artworks"
  add_foreign_key "voting_session_artwork_scores", "exhibitions"
  add_foreign_key "voting_session_artwork_scores", "voting_sessions"
end
