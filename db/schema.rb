ActiveRecord::Schema[8.0].define(version: 2026_02_18_000009) do
  create_table "detections", force: :cascade do |t|
    t.bigint "station_id", null: false
    t.string "artist", null: false
    t.string "title", null: false
    t.string "artist_title_normalized", null: false
    t.datetime "played_at", null: false
    t.float "confidence", default: 1.0
    t.string "source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["artist_title_normalized"], name: "index_detections_on_artist_title_normalized"
    t.index ["played_at"], name: "index_detections_on_played_at"
    t.index ["station_id", "played_at"], name: "index_detections_on_station_id_and_played_at"
    t.index ["station_id"], name: "index_detections_on_station_id"
  end

  create_table "identities", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.string "access_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "uid"], name: "index_identities_on_provider_and_uid", unique: true
    t.index ["user_id"], name: "index_identities_on_user_id"
  end

  create_table "playlist_items", force: :cascade do |t|
    t.bigint "playlist_id", null: false
    t.string "track_artist"
    t.string "track_title"
    t.integer "position", null: false
    t.string "status", default: "resolved", null: false
    t.bigint "captured_station_id"
    t.datetime "captured_at"
    t.bigint "resolved_detection_id"
    t.datetime "resolved_at"
    t.string "unresolved_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["playlist_id", "position"], name: "index_playlist_items_on_playlist_id_and_position"
    t.index ["playlist_id"], name: "index_playlist_items_on_playlist_id"
    t.index ["status"], name: "index_playlist_items_on_status"
  end

  create_table "playlists", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title", null: false
    t.string "local_id"
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "local_id"], name: "index_playlists_on_user_id_and_local_id"
    t.index ["user_id"], name: "index_playlists_on_user_id"
  end

  create_table "station_bookmarks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "station_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["station_id"], name: "index_station_bookmarks_on_station_id"
    t.index ["user_id", "station_id"], name: "index_station_bookmarks_on_user_id_and_station_id", unique: true
    t.index ["user_id"], name: "index_station_bookmarks_on_user_id"
  end

  create_table "stations", force: :cascade do |t|
    t.string "code", null: false
    t.string "title", null: false
    t.string "player_url", null: false
    t.text "description"
    t.boolean "active", default: true
    t.boolean "federal", default: true
    t.bigint "now_playing_track_id"
    t.string "stream_url"
    t.boolean "contest_enabled", default: true
    t.string "contest_page_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_stations_on_active"
    t.index ["code"], name: "index_stations_on_code", unique: true
    t.index ["federal"], name: "index_stations_on_federal"
    t.index ["now_playing_track_id"], name: "index_stations_on_now_playing_track_id"
  end

  create_table "tune_in_attempts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "track_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_tune_in_attempts_on_created_at"
    t.index ["track_id"], name: "index_tune_in_attempts_on_track_id"
    t.index ["user_id"], name: "index_tune_in_attempts_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "paid_until"
    t.string "plan_code", default: "guest"
    t.integer "trial_tune_in_remaining", default: 3
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["paid_until"], name: "index_users_on_paid_until"
  end

  add_foreign_key "detections", "stations"
  add_foreign_key "identities", "users"
  add_foreign_key "playlist_items", "detections", column: "resolved_detection_id"
  add_foreign_key "playlist_items", "playlists"
  add_foreign_key "playlist_items", "stations", column: "captured_station_id"
  add_foreign_key "playlists", "users"
  add_foreign_key "station_bookmarks", "stations"
  add_foreign_key "station_bookmarks", "users"
  add_foreign_key "stations", "detections", column: "now_playing_track_id"
  add_foreign_key "tune_in_attempts", "detections", column: "track_id"
  add_foreign_key "tune_in_attempts", "users"
end
