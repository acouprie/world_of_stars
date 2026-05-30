class Building < ApplicationRecord
  VALID_TYPES = Buildings::REGISTRY.keys.map(&:to_s).freeze

  belongs_to :planet

  validates :building_type, presence: true, inclusion: { in: VALID_TYPES }
  validates :level, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :planet_id, uniqueness: { scope: :building_type }

  def config
    Buildings::REGISTRY[building_type.to_sym]
  end
end
