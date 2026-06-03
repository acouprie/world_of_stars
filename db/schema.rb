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

ActiveRecord::Schema[8.1].define(version: 2026_05_30_100003) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "buildings", force: :cascade do |t|
    t.string "building_type", null: false
    t.datetime "created_at", null: false
    t.integer "level", default: 0, null: false
    t.bigint "planet_id", null: false
    t.integer "slot_index", null: false
    t.datetime "updated_at", null: false
    t.index ["planet_id", "building_type"], name: "index_buildings_on_planet_id_and_building_type", unique: true
    t.index ["planet_id"], name: "index_buildings_on_planet_id"
  end

  create_table "construction_queues", force: :cascade do |t|
    t.bigint "building_id", null: false
    t.datetime "completes_at", null: false
    t.datetime "created_at", null: false
    t.bigint "planet_id", null: false
    t.string "sidekiq_job_id"
    t.datetime "started_at", null: false
    t.string "status", default: "pending", null: false
    t.integer "target_level", null: false
    t.datetime "updated_at", null: false
    t.index ["building_id"], name: "index_construction_queues_on_building_id"
    t.index ["planet_id"], name: "index_construction_queues_on_planet_id", unique: true
  end

  create_table "planets", force: :cascade do |t|
    t.string "biome", default: "forest", null: false
    t.integer "coord_x", null: false
    t.integer "coord_y", null: false
    t.datetime "created_at", null: false
    t.decimal "food_stock", precision: 15, scale: 4, default: "0.0", null: false
    t.boolean "is_home", default: false, null: false
    t.decimal "metal_stock", precision: 15, scale: 4, default: "0.0", null: false
    t.string "name", null: false
    t.string "planet_type", default: "empty", null: false
    t.datetime "resources_updated_at", null: false
    t.decimal "thorium_stock", precision: 15, scale: 4, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["coord_x", "coord_y"], name: "index_planets_on_coord_x_and_coord_y", unique: true
    t.index ["planet_type"], name: "index_planets_on_planet_type"
    t.index ["user_id"], name: "index_planets_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "buildings", "planets"
  add_foreign_key "construction_queues", "buildings"
  add_foreign_key "construction_queues", "planets"
  add_foreign_key "planets", "users"
  add_foreign_key "sessions", "users"
end
