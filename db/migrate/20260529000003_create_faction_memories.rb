class CreateFactionMemories < ActiveRecord::Migration[8.1]
  def change
    create_table :faction_memories do |t|
      t.string :faction, null: false      # varek | elyrans | nexhari
      t.string :memory_type, null: false  # objective | last_decision | target_priority | reputation
      t.jsonb :content, null: false, default: {}
      t.timestamps
    end

    add_index :faction_memories, :faction
    add_index :faction_memories, [:faction, :memory_type]
    add_index :faction_memories, :content, using: :gin
  end
end
