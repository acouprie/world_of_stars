class CreateUnits < ActiveRecord::Migration[8.1]
  def change
    create_table :units do |t|
      t.references :planet, null: false, foreign_key: true
      t.string  :unit_type, null: false
      t.integer :count, null: false, default: 0

      t.timestamps
    end

    add_index :units, [:planet_id, :unit_type], unique: true
  end
end
