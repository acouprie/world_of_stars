class CombatMission < ApplicationRecord
  belongs_to :planet
  belongs_to :target_planet, class_name: "Planet"

  validates :status, inclusion: { in: %w[traveling completed] }

  scope :traveling, -> { where(status: "traveling") }
  scope :completed, -> { where(status: "completed") }
  scope :recent,    -> { order(started_at: :desc) }

  scope :involving, ->(planet) {
    where(planet: planet).or(where(target_planet: planet))
  }

  def traveling? = status == "traveling"
  def completed? = status == "completed"
end
