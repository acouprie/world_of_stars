class Planet < ApplicationRecord
  PLANET_TYPES  = %w[player ai_faction empty].freeze
  BIOMES = %w[
    oceanic arid volcanic glacial forest
    temperate tundra crystalline fungal toxic irradiated barren
  ].freeze

  BIOME_BONUSES = {
    oceanic:     { food: 1.5, metal: 1.5 },
    arid:        { metal: 3.0 },
    volcanic:    { thorium: 3.0 },
    glacial:     { thorium: 2.0, metal: 1.0 },
    forest:      { food: 3.0 },
    temperate:   { metal: 1.0, food: 1.0, thorium: 1.0 },
    tundra:      { metal: 2.0, food: 1.0 },
    crystalline: { thorium: 2.0, metal: 1.0 },
    fungal:      { food: 2.0, thorium: 1.0 },
    toxic:       { food: 1.5, thorium: 1.5 },
    irradiated:  { thorium: 2.0, food: 1.0 },
    barren:      { metal: 2.0, thorium: 1.0 },
  }.freeze

  belongs_to :user, optional: true
  has_many :buildings, dependent: :destroy
  has_one  :construction_queue, dependent: :destroy

  validates :planet_type,  inclusion: { in: PLANET_TYPES }
  validates :biome,  inclusion: { in: BIOMES }
  validates :name, presence: true
  validates :coord_x, :coord_y, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :is_home, inclusion: { in: [true, false] }
  validates :metal_stock, :food_stock, :thorium_stock, numericality: { greater_than_or_equal_to: 0 }

  def total_energy_produced
    buildings.sum { |b| Buildings::Calculator.energy_produced(b.building_type, b.level) }
  end

  def total_energy_consumed
    buildings.sum { |b| Buildings::Calculator.energy_consumed(b.building_type, b.level) }
  end

  def net_energy
    total_energy_produced - total_energy_consumed
  end

  def metal_capacity
    b = buildings.find { |bld| bld.building_type == "metal_warehouse" }
    Buildings::Calculator.storage_capacity(:metal_warehouse, b&.level || 0)
  end

  def food_capacity
    b = buildings.find { |bld| bld.building_type == "food_silo" }
    Buildings::Calculator.storage_capacity(:food_silo, b&.level || 0)
  end

  def thorium_capacity
    b = buildings.find { |bld| bld.building_type == "thorium_warehouse" }
    Buildings::Calculator.storage_capacity(:thorium_warehouse, b&.level || 0)
  end

  def metal_rate
    b = buildings.find { |bld| bld.building_type == "metal_mine" }
    base = Buildings::Calculator.production_rate(:metal_mine, b&.level || 0)
    base + biome_bonus(:metal) * Math.sqrt(base)
  end

  def food_rate
    b = buildings.find { |bld| bld.building_type == "farm" }
    base = Buildings::Calculator.production_rate(:farm, b&.level || 0)
    base + biome_bonus(:food) * Math.sqrt(base)
  end

  def thorium_rate
    b = buildings.find { |bld| bld.building_type == "thorium_mine" }
    base = Buildings::Calculator.production_rate(:thorium_mine, b&.level || 0)
    base + biome_bonus(:thorium) * Math.sqrt(base)
  end

  def biome_bonus(resource)
    BIOME_BONUSES.dig(biome.to_sym, resource) || 0.0
  end

  def available_building_types
    built_levels = buildings.where("level >= 1").each_with_object({}) do |b, h|
      h[b.building_type.to_sym] = b.level
    end
    Buildings::REGISTRY.select do |type, config|
      next false if built_levels.key?(type)
      (config[:requires] || {}).all? { |req_type, req_level|
        built_levels.fetch(req_type, 0) >= req_level
      }
    end.keys
  end

  # Must be called inside a with_lock block.
  def calculate_resources!(now: Time.current)
    elapsed = (now - resources_updated_at).to_f
    elapsed = 0.0 if elapsed < 0

    self.metal_stock   = [[metal_stock.to_f   + metal_rate   * elapsed, 0].max, metal_capacity].min
    self.food_stock    = [[food_stock.to_f    + food_rate    * elapsed, 0].max, food_capacity].min
    self.thorium_stock = [[thorium_stock.to_f + thorium_rate * elapsed, 0].max, thorium_capacity].min
    self.resources_updated_at = now
    save!
  end
end
