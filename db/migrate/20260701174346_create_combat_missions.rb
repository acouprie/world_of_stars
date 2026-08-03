class CreateCombatMissions < ActiveRecord::Migration[8.1]
  def change
    create_table :combat_missions do |t|
      t.references :planet,           null: false, foreign_key: true
      t.bigint     :target_planet_id, null: false
      t.string     :status,           null: false, default: "traveling"
      t.datetime   :started_at,       null: false
      t.datetime   :arrives_at,       null: false
      t.jsonb      :attacker_force,   null: false
      t.jsonb      :defender_force_snapshot
      t.string     :outcome
      t.jsonb      :attacker_losses
      t.jsonb      :defender_losses
      t.integer    :rounds_count
      t.integer    :metal_pillaged,      default: 0
      t.integer    :food_pillaged,       default: 0
      t.integer    :thorium_pillaged,    default: 0
      t.integer    :attacker_xp_gained,  default: 0
      t.integer    :defender_xp_gained,  default: 0
      t.text       :narrative_report
      t.timestamps
    end

    add_foreign_key :combat_missions, :planets, column: :target_planet_id
    add_index :combat_missions, :target_planet_id
    add_index :combat_missions, [:planet_id, :status]
  end
end
