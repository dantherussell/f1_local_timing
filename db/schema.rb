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

ActiveRecord::Schema[8.1].define(version: 2026_01_16_134451) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "days", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.string "local_time_offset"
    t.datetime "updated_at", null: false
    t.bigint "weekend_id", null: false
    t.index ["weekend_id", "date"], name: "index_days_on_weekend_id_and_date", unique: true
    t.index ["weekend_id"], name: "index_days_on_weekend_id"
  end

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "day_id", null: false
    t.string "local_time_offset"
    t.string "name"
    t.string "racing_class"
    t.bigint "session_id"
    t.time "start_time"
    t.datetime "updated_at", null: false
    t.index ["day_id"], name: "index_events_on_day_id"
    t.index ["session_id"], name: "index_events_on_session_id"
  end

  create_table "seasons", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "series", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.bigint "series_id", null: false
    t.datetime "updated_at", null: false
    t.index ["series_id"], name: "index_sessions_on_series_id"
  end

  create_table "weekends", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "first_day"
    t.string "gp_title"
    t.date "last_day"
    t.string "local_time_offset"
    t.string "local_timezone"
    t.string "location"
    t.integer "race_number"
    t.bigint "season_id", null: false
    t.datetime "updated_at", null: false
    t.index ["season_id"], name: "index_weekends_on_season_id"
  end

  add_foreign_key "days", "weekends"
  add_foreign_key "events", "days"
  add_foreign_key "events", "sessions"
  add_foreign_key "sessions", "series"
  add_foreign_key "weekends", "seasons"
end
