class CreateBuildings < ActiveRecord::Migration[8.1]
  def change
    create_table :buildings do |t|
      t.references :planet,        null: false, foreign_key: true
      t.string     :building_type, null: false
      t.integer    :level,         null: false, default: 0
      t.integer    :slot_index,    null: false

      t.timestamps
    end

    add_index :buildings, [:planet_id, :building_type], unique: true
  end
end
