class CreateConstructionQueues < ActiveRecord::Migration[8.1]
  def change
    create_table :construction_queues do |t|
      t.references :planet,   null: false, foreign_key: true, index: { unique: true }
      t.references :building, null: false, foreign_key: true
      t.integer    :target_level,   null: false
      t.string     :status,         null: false, default: "pending"
      t.datetime   :started_at,     null: false
      t.datetime   :completes_at,   null: false
      t.string     :sidekiq_job_id

      t.timestamps
    end
  end
end
