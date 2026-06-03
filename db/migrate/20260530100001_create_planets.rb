class CreatePlanets < ActiveRecord::Migration[8.1]
  def change
    create_table :planets do |t|
      t.references :user, null: true, foreign_key: true
      t.string   :planet_type,          null: false, default: "empty"
      t.string   :biome,                null: false, default: "forest"
      t.string   :name,                 null: false
      t.integer  :coord_x,              null: false
      t.integer  :coord_y,              null: false
      t.boolean  :is_home,              null: false, default: false
      t.decimal  :metal_stock,          null: false, default: 0, precision: 15, scale: 4
      t.decimal  :food_stock,           null: false, default: 0, precision: 15, scale: 4
      t.decimal  :thorium_stock,        null: false, default: 0, precision: 15, scale: 4
      t.datetime :resources_updated_at, null: false

      t.timestamps
    end

    add_index :planets, [:coord_x, :coord_y], unique: true
    add_index :planets, :planet_type
  end
end
