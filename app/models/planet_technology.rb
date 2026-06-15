class PlanetTechnology < ApplicationRecord
  VALID_KEYS   = Technologies::REGISTRY.keys.map(&:to_s).freeze
  STATUSES     = %w[idle researching].freeze

  belongs_to :planet

  validates :tech_key, presence: true, inclusion: { in: VALID_KEYS }
  validates :level,    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :status,   inclusion: { in: STATUSES }
  validates :planet_id, uniqueness: { scope: :tech_key }

  def idle?        = status == "idle"
  def researching? = status == "researching"
end
