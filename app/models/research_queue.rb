class ResearchQueue < ApplicationRecord
  STATUSES = %w[pending completed cancelled].freeze

  belongs_to :planet

  validates :tech_key,     presence: true
  validates :target_level, numericality: { only_integer: true, greater_than: 0 }
  validates :status,       inclusion: { in: STATUSES }
  validates :finishes_at,  presence: true
  validate  :only_one_pending_per_planet, if: :pending?

  scope :pending,   -> { where(status: "pending") }
  scope :completed, -> { where(status: "completed") }
  scope :cancelled, -> { where(status: "cancelled") }

  def pending?   = status == "pending"
  def completed? = status == "completed"
  def cancelled? = status == "cancelled"

  private

  def only_one_pending_per_planet
    scope = self.class.where(planet_id: planet_id, status: "pending")
    scope = scope.where.not(id: id) unless new_record?
    errors.add(:base, "a research is already pending for this planet") if scope.exists?
  end
end
