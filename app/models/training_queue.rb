class TrainingQueue < ApplicationRecord
  STATUSES = %w[pending completed cancelled].freeze

  belongs_to :planet

  validates :unit_type, presence: true, inclusion: { in: Units::REGISTRY.keys.map(&:to_s) }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }
  validates :started_at, :completes_at, presence: true
  validate  :completes_at_after_started_at

  scope :pending,   -> { where(status: "pending") }
  scope :completed, -> { where(status: "completed") }
  scope :cancelled, -> { where(status: "cancelled") }

  def pending?   = status == "pending"
  def completed? = status == "completed"
  def cancelled? = status == "cancelled"

  private

  def completes_at_after_started_at
    return unless started_at && completes_at
    errors.add(:completes_at, "must be after started_at") if completes_at <= started_at
  end
end
