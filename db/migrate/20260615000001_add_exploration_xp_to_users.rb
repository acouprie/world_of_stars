class AddExplorationXpToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :exploration_xp, :integer, default: 0, null: false
  end
end
