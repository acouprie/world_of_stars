class CreateResearchQueues < ActiveRecord::Migration[8.1]
  def change
    create_table :research_queues do |t|
      t.references :planet,       null: false, foreign_key: true
      t.string     :tech_key,     null: false
      t.integer    :target_level, null: false
      t.string     :status,       default: "pending", null: false
      t.datetime   :started_at,   null: false
      t.datetime   :completes_at, null: false
      t.integer    :metal_cost,   null: false
      t.integer    :food_cost,    null: false
      t.integer    :thorium_cost, null: false
      t.string     :sidekiq_job_id
      t.timestamps
    end

    add_index :research_queues, :status
  end
end
