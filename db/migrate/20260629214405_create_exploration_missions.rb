class CreateExplorationMissions < ActiveRecord::Migration[8.1]
  def change
    create_table :exploration_missions do |t|
      t.references :planet,           null: false, foreign_key: true
      t.bigint     :target_planet_id, null: false
      t.string     :status,           null: false, default: "pending"
      t.datetime   :started_at,       null: false
      t.datetime   :finishes_at,      null: false
      t.jsonb      :force_snapshot,   null: false
      t.integer    :exploration_points, default: 0
      t.integer    :metal_gained,     default: 0
      t.integer    :food_gained,      default: 0
      t.integer    :thorium_gained,   default: 0
      t.jsonb      :losses_snapshot
      t.text       :narrative_report
      t.timestamps
    end

    add_foreign_key :exploration_missions, :planets, column: :target_planet_id
    add_index :exploration_missions, [:planet_id, :status]
  end
end
