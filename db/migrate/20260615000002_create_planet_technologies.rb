class CreatePlanetTechnologies < ActiveRecord::Migration[8.1]
  def change
    create_table :planet_technologies do |t|
      t.references :planet, null: false, foreign_key: true
      t.string     :tech_key, null: false
      t.integer    :level,  default: 0,    null: false
      t.string     :status, default: "idle", null: false
      t.timestamps
    end

    add_index :planet_technologies, [:planet_id, :tech_key], unique: true
  end
end
