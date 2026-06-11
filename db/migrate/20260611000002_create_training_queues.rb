class CreateTrainingQueues < ActiveRecord::Migration[8.1]
  def change
    create_table :training_queues do |t|
      t.references :planet, null: false, foreign_key: true
      t.string   :unit_type,     null: false
      t.integer  :quantity,      null: false
      t.string   :status,        null: false, default: "pending"
      t.datetime :started_at,    null: false
      t.datetime :completes_at,  null: false
      t.string   :sidekiq_job_id

      t.timestamps
    end

    add_index :training_queues, :status
  end
end
