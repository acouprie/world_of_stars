class Unit < ApplicationRecord
  VALID_TYPES = Units::REGISTRY.keys.map(&:to_s).freeze

  belongs_to :planet

  validates :unit_type, presence: true, inclusion: { in: VALID_TYPES }
  validates :count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :planet_id, uniqueness: { scope: :unit_type }
end
