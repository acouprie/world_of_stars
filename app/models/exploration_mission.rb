class ExplorationMission < ApplicationRecord
  belongs_to :planet
  belongs_to :target_planet, class_name: "Planet"

  validates :status, inclusion: { in: %w[pending completed] }
  validate  :max_simultaneous_missions, if: -> { status == "pending" }

  scope :pending,   -> { where(status: "pending") }
  scope :completed, -> { where(status: "completed") }
  scope :recent,    -> { order(started_at: :desc) }

  def pending?   = status == "pending"
  def completed? = status == "completed"

  private

  def max_simultaneous_missions
    count = planet.exploration_missions.pending.count
    count -= 1 if persisted?
    errors.add(:base, :max_simultaneous_reached) if count >= Explorations::MAX_SIMULTANEOUS_EXPLORATIONS
  end
end
