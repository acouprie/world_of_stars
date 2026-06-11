module Units
  TRAINING_TIME_COEFFICIENT = 0.95

  # Universal prerequisite for all unit training: training_camp must be built.
  # training_camp level reduces training time but does NOT gate unit types.
  UNIVERSAL_REQUIRES = { training_camp: 1 }.freeze

  # Static registry — source of truth for all unit types.
  #
  # Fields:
  #   category   — :combat | :exploration | :reconnaissance | :transport
  #   combat     — true ONLY for maraudeur, regulier, sentinelle; false for all others
  #                including scientifique (ATQ 2 but not a combat unit per combat_reference §6)
  #   stats      — { atk, def, int, transport, exploration, espionage } — baseline v2.1
  #   cost       — { metal, food, thorium } — calibration placeholder (scale factor k=1 from unit_reference §4)
  #   base_time  — formation time in seconds at training_camp level 1
  #   requires   — unlock prerequisites (military_camp level, research_lab level, or technology key)
  #                technology: :key means the player must have researched that technology at level >= 1
  REGISTRY = {
    maraudeur: {
      category: :combat,
      combat: true,
      stats: { atk: 16, def: 20, int: 6, transport: 50, exploration: :minor_fixed, espionage: 0 },
      cost: { metal: 70, food: 30, thorium: 0 },
      base_time: 450,
      requires: { military_camp: 1 }
    },
    regulier: {
      category: :combat,
      combat: true,
      stats: { atk: 11, def: 30, int: 8, transport: 80, exploration: :minor_fixed, espionage: 0 },
      cost: { metal: 75, food: 30, thorium: 10 },
      base_time: 630,
      requires: { military_camp: 3, technology: :armement }
    },
    sentinelle: {
      category: :combat,
      combat: true,
      stats: { atk: 13, def: 38, int: 10, transport: 30, exploration: :minor_fixed, espionage: 0 },
      cost: { metal: 95, food: 35, thorium: 30 },
      base_time: 750,
      requires: { military_camp: 5, technology: :blindage_tactique }
    },
    scientifique: {
      category: :exploration,
      combat: false,
      stats: { atk: 2, def: 14, int: 7, transport: 60, exploration: :main, espionage: 0 },
      cost: { metal: 60, food: 45, thorium: 25 },
      base_time: 750,
      requires: { research_lab: 1 }
    },
    sonde: {
      category: :reconnaissance,
      combat: false,
      stats: { atk: 0, def: 12, int: 4, transport: 150, exploration: :minor, espionage: 3 },
      cost: { metal: 80, food: 40, thorium: 30 },
      base_time: 750,
      requires: { military_camp: 1 }
    },
    spectre: {
      category: :reconnaissance,
      combat: false,
      stats: { atk: 0, def: 10, int: 2, transport: 0, exploration: :minor, espionage: 12 },
      cost: { metal: 70, food: 25, thorium: 40 },
      base_time: 900,
      requires: { military_camp: 6, technology: :guerre_electronique }
    },
    mule: {
      category: :transport,
      combat: false,
      stats: { atk: 0, def: 16, int: 1, transport: 350, exploration: nil, espionage: 0 },
      cost: { metal: 70, food: 40, thorium: 0 },
      base_time: 750,
      requires: { military_camp: 2 }
    }
  }.freeze

  def self.find!(type)
    REGISTRY.fetch(type.to_sym) { raise ArgumentError, "Unknown unit type: #{type}" }
  end

  def self.cost_for(type)
    find!(type)[:cost]
  end

  def self.combat?(type)
    find!(type)[:combat]
  end

  # Returns training duration in seconds for one unit at the given training_camp level.
  # Formula: base_time × TRAINING_TIME_COEFFICIENT^(camp_level − 1)
  # camp_level is floored at 1 so the formula never produces a result longer than base_time.
  def self.training_time(type, training_camp_level)
    base  = find!(type)[:base_time]
    level = [training_camp_level.to_i, 1].max
    (base * TRAINING_TIME_COEFFICIENT**(level - 1)).ceil
  end

  # Returns true if the unit type is unlocked for the given planet.
  # Checks UNIVERSAL_REQUIRES (training_camp 1) and unit-specific requires.
  # Requires planet.buildings to be available (eager-loaded or lazy-loaded).
  def self.unlocked?(type, planet)
    config = find!(type)
    built  = planet.buildings.each_with_object({}) { |b, h| h[b.building_type.to_sym] = b.level }
    all_requires = UNIVERSAL_REQUIRES.merge(config[:requires] || {})
    all_requires.all? do |req_type, req_value|
      case req_type
      when :technology
        (planet.user&.technology_level(req_value) || 0) >= 1
      else
        built.fetch(req_type, 0) >= req_value
      end
    end
  end

  # Stub hooks — to be implemented in dedicated prompts.
  def self.explore(units) = {}
  def self.spy(units) = {}
end
