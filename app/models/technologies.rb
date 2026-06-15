module Technologies
  VALID_KEYS = %i[
    forage_cristallin hydroponie raffinage_thorium conversion_energetique
    armement blindage_tactique guerre_electronique cartographie_stellaire
    technologie_cristal
  ].freeze

  REGISTRY = {
    forage_cristallin: {
      category: :production, scope: :initial, max_level: 18,
      requires: { research_lab: 1, exploration: 1 },
      effect: { type: :metal_production_bonus, per_level: 0.06 },
      levels: [
        { metal: 800,    food: 480,    thorium: 320,   time: 480    },
        { metal: 1125,   food: 670,    thorium: 450,   time: 720    },
        { metal: 1575,   food: 940,    thorium: 625,   time: 1140   },
        { metal: 2200,   food: 1325,   thorium: 880,   time: 1800   },
        { metal: 3075,   food: 1850,   thorium: 1225,  time: 2760   },
        { metal: 4300,   food: 2575,   thorium: 1725,  time: 4320   },
        { metal: 6025,   food: 3625,   thorium: 2400,  time: 6660   },
        { metal: 8425,   food: 5050,   thorium: 3375,  time: 10320  },
        { metal: 11800,  food: 7075,   thorium: 4725,  time: 16020  },
        { metal: 16500,  food: 9925,   thorium: 6600,  time: 24780  },
        { metal: 23100,  food: 13900,  thorium: 9250,  time: 38400  },
        { metal: 32400,  food: 19400,  thorium: 13000, time: 59580  },
        { metal: 45400,  food: 27200,  thorium: 18100, time: 90000  },
        { metal: 63500,  food: 38100,  thorium: 25400, time: 140400 },
        { metal: 88900,  food: 53300,  thorium: 35600, time: 219600 },
        { metal: 124500, food: 74700,  thorium: 49800, time: 342000 },
        { metal: 174000, food: 104500, thorium: 69700, time: 532800 },
        { metal: 244000, food: 146500, thorium: 97600, time: 824400 }
      ]
    },
    hydroponie: {
      category: :production, scope: :initial, max_level: 18,
      requires: { research_lab: 1, exploration: 1 },
      effect: { type: :food_production_bonus, per_level: 0.06 },
      levels: [
        { metal: 800,    food: 480,    thorium: 320,   time: 480    },
        { metal: 1125,   food: 670,    thorium: 450,   time: 720    },
        { metal: 1575,   food: 940,    thorium: 625,   time: 1140   },
        { metal: 2200,   food: 1325,   thorium: 880,   time: 1800   },
        { metal: 3075,   food: 1850,   thorium: 1225,  time: 2760   },
        { metal: 4300,   food: 2575,   thorium: 1725,  time: 4320   },
        { metal: 6025,   food: 3625,   thorium: 2400,  time: 6660   },
        { metal: 8425,   food: 5050,   thorium: 3375,  time: 10320  },
        { metal: 11800,  food: 7075,   thorium: 4725,  time: 16020  },
        { metal: 16500,  food: 9925,   thorium: 6600,  time: 24780  },
        { metal: 23100,  food: 13900,  thorium: 9250,  time: 38400  },
        { metal: 32400,  food: 19400,  thorium: 13000, time: 59580  },
        { metal: 45400,  food: 27200,  thorium: 18100, time: 90000  },
        { metal: 63500,  food: 38100,  thorium: 25400, time: 140400 },
        { metal: 88900,  food: 53300,  thorium: 35600, time: 219600 },
        { metal: 124500, food: 74700,  thorium: 49800, time: 342000 },
        { metal: 174000, food: 104500, thorium: 69700, time: 532800 },
        { metal: 244000, food: 146500, thorium: 97600, time: 824400 }
      ]
    },
    raffinage_thorium: {
      category: :production, scope: :initial, max_level: 15,
      requires: { research_lab: 2, exploration: 2, forage_cristallin: 5 },
      effect: { type: :thorium_production_bonus, per_level: 0.06 },
      levels: [
        { metal: 1200,  food: 720,   thorium: 480,  time: 600    },
        { metal: 1675,  food: 1000,  thorium: 670,  time: 960    },
        { metal: 2350,  food: 1400,  thorium: 940,  time: 1440   },
        { metal: 3300,  food: 1975,  thorium: 1325, time: 2220   },
        { metal: 4600,  food: 2775,  thorium: 1850, time: 3480   },
        { metal: 6450,  food: 3875,  thorium: 2575, time: 5340   },
        { metal: 9025,  food: 5425,  thorium: 3625, time: 8340   },
        { metal: 12600, food: 7600,  thorium: 5050, time: 12900  },
        { metal: 17700, food: 10600, thorium: 7075, time: 19980  },
        { metal: 24800, food: 14900, thorium: 9925, time: 30960  },
        { metal: 34700, food: 20800, thorium: 13900, time: 48000 },
        { metal: 48600, food: 29200, thorium: 19400, time: 74460 },
        { metal: 68000, food: 40800, thorium: 27200, time: 115200 },
        { metal: 95200, food: 57100, thorium: 38100, time: 176400 },
        { metal: 133500, food: 80000, thorium: 53300, time: 277200 }
      ]
    },
    conversion_energetique: {
      category: :energy, scope: :initial, max_level: 10,
      requires: { research_lab: 1, exploration: 1 },
      effect: { type: :solar_production_bonus, per_level: 0.04 },
      levels: [
        { metal: 320,  food: 200,  thorium: 280,  time: 360   },
        { metal: 465,  food: 290,  thorium: 405,  time: 600   },
        { metal: 675,  food: 420,  thorium: 590,  time: 900   },
        { metal: 975,  food: 610,  thorium: 855,  time: 1500  },
        { metal: 1425, food: 885,  thorium: 1250, time: 2340  },
        { metal: 2050, food: 1275, thorium: 1800, time: 3780  },
        { metal: 2975, food: 1850, thorium: 2600, time: 6060  },
        { metal: 4300, food: 2700, thorium: 3775, time: 9660  },
        { metal: 6250, food: 3900, thorium: 5475, time: 15480 },
        { metal: 9075, food: 5675, thorium: 7925, time: 24720 }
      ]
    },
    armement: {
      category: :military, scope: :initial, max_level: 18,
      requires: { research_lab: 1, exploration: 1 },
      effect: { type: :unit_attack_bonus, per_level: 0.04 },
      levels: [
        { metal: 720,    food: 320,   thorium: 560,   time: 480    },
        { metal: 1000,   food: 450,   thorium: 785,   time: 720    },
        { metal: 1400,   food: 625,   thorium: 1100,  time: 1140   },
        { metal: 1975,   food: 880,   thorium: 1525,  time: 1800   },
        { metal: 2775,   food: 1225,  thorium: 2150,  time: 2760   },
        { metal: 3875,   food: 1725,  thorium: 3000,  time: 4320   },
        { metal: 5425,   food: 2400,  thorium: 4225,  time: 6660   },
        { metal: 7600,   food: 3375,  thorium: 5900,  time: 10320  },
        { metal: 10600,  food: 4725,  thorium: 8275,  time: 16020  },
        { metal: 14900,  food: 6600,  thorium: 11600, time: 24780  },
        { metal: 20800,  food: 9250,  thorium: 16200, time: 38400  },
        { metal: 29200,  food: 13000, thorium: 22700, time: 59580  },
        { metal: 40800,  food: 18100, thorium: 31700, time: 90000  },
        { metal: 57100,  food: 25400, thorium: 44400, time: 140400 },
        { metal: 80000,  food: 35600, thorium: 62200, time: 219600 },
        { metal: 112000, food: 49800, thorium: 87100, time: 342000 },
        { metal: 157000, food: 69700, thorium: 122000, time: 532800 },
        { metal: 219500, food: 97600, thorium: 171000, time: 824400 }
      ]
    },
    blindage_tactique: {
      category: :military, scope: :initial, max_level: 18,
      requires: { research_lab: 1, exploration: 1 },
      effect: { type: :unit_defense_bonus, per_level: 0.04 },
      levels: [
        { metal: 720,    food: 320,   thorium: 560,   time: 480    },
        { metal: 1000,   food: 450,   thorium: 785,   time: 720    },
        { metal: 1400,   food: 625,   thorium: 1100,  time: 1140   },
        { metal: 1975,   food: 880,   thorium: 1525,  time: 1800   },
        { metal: 2775,   food: 1225,  thorium: 2150,  time: 2760   },
        { metal: 3875,   food: 1725,  thorium: 3000,  time: 4320   },
        { metal: 5425,   food: 2400,  thorium: 4225,  time: 6660   },
        { metal: 7600,   food: 3375,  thorium: 5900,  time: 10320  },
        { metal: 10600,  food: 4725,  thorium: 8275,  time: 16020  },
        { metal: 14900,  food: 6600,  thorium: 11600, time: 24780  },
        { metal: 20800,  food: 9250,  thorium: 16200, time: 38400  },
        { metal: 29200,  food: 13000, thorium: 22700, time: 59580  },
        { metal: 40800,  food: 18100, thorium: 31700, time: 90000  },
        { metal: 57100,  food: 25400, thorium: 44400, time: 140400 },
        { metal: 80000,  food: 35600, thorium: 62200, time: 219600 },
        { metal: 112000, food: 49800, thorium: 87100, time: 342000 },
        { metal: 157000, food: 69700, thorium: 122000, time: 532800 },
        { metal: 219500, food: 97600, thorium: 171000, time: 824400 }
      ]
    },
    guerre_electronique: {
      category: :military, scope: :initial, max_level: 15,
      requires: { research_lab: 2, exploration: 2 },
      effect: { type: :unit_intelligence_bonus, per_level: 0.04 },
      levels: [
        { metal: 1075,  food: 480,   thorium: 840,  time: 600    },
        { metal: 1500,  food: 670,   thorium: 1175, time: 960    },
        { metal: 2125,  food: 940,   thorium: 1650, time: 1440   },
        { metal: 2975,  food: 1325,  thorium: 2300, time: 2220   },
        { metal: 4150,  food: 1850,  thorium: 3225, time: 3480   },
        { metal: 5800,  food: 2575,  thorium: 4525, time: 5340   },
        { metal: 8125,  food: 3625,  thorium: 6325, time: 8340   },
        { metal: 11400, food: 5050,  thorium: 8850, time: 12900  },
        { metal: 15900, food: 7075,  thorium: 12400, time: 19980 },
        { metal: 22300, food: 9925,  thorium: 17400, time: 30960 },
        { metal: 31200, food: 13900, thorium: 24300, time: 48000 },
        { metal: 43700, food: 19400, thorium: 34000, time: 74460 },
        { metal: 61200, food: 27200, thorium: 47600, time: 115200 },
        { metal: 85700, food: 38100, thorium: 66700, time: 176400 },
        { metal: 120000, food: 53300, thorium: 93300, time: 277200 }
      ]
    },
    cartographie_stellaire: {
      category: :exploration, scope: :initial, max_level: 10,
      requires: { research_lab: 1, exploration: 1 },
      effect: { type: :exploration_xp_bonus, per_level: 0.04 },
      levels: [
        { metal: 400,   food: 250,  thorium: 350,  time: 360   },
        { metal: 580,   food: 360,  thorium: 505,  time: 600   },
        { metal: 840,   food: 525,  thorium: 735,  time: 900   },
        { metal: 1225,  food: 760,  thorium: 1075, time: 1500  },
        { metal: 1775,  food: 1100, thorium: 1550, time: 2340  },
        { metal: 2575,  food: 1600, thorium: 2250, time: 3780  },
        { metal: 3725,  food: 2325, thorium: 3250, time: 6060  },
        { metal: 5400,  food: 3375, thorium: 4725, time: 9660  },
        { metal: 7825,  food: 4875, thorium: 6850, time: 15480 },
        { metal: 11300, food: 7075, thorium: 9925, time: 24720 }
      ]
    },
    technologie_cristal: {
      category: :gate, scope: :initial, max_level: 1,
      requires: { research_lab: 1, exploration: 1 },
      effect: { type: :building_unlock, per_level: nil },
      levels: [
        { metal: 800, food: 400, thorium: 800, time: 1800 }
      ]
    }
  }.freeze

  LEVEL_PREREQUISITES = {
    forage_cristallin: {
      7  => { research_lab: 4, exploration: 4 },
      13 => { research_lab: 7, exploration: 6 },
      17 => { research_lab: 10, exploration: 8 }
    },
    hydroponie: {
      7  => { research_lab: 4, exploration: 4 },
      13 => { research_lab: 7, exploration: 6 },
      17 => { research_lab: 10, exploration: 8 }
    },
    raffinage_thorium: {
      6  => { research_lab: 5, exploration: 4 },
      11 => { research_lab: 8, exploration: 6 }
    },
    conversion_energetique: {
      6 => { research_lab: 4, exploration: 3 }
    },
    armement: {
      7  => { research_lab: 4, military_camp: 4, exploration: 4 },
      13 => { research_lab: 7, military_camp: 7, exploration: 6 },
      17 => { research_lab: 10, military_camp: 9, exploration: 8 }
    },
    blindage_tactique: {
      7  => { research_lab: 4, military_camp: 4, exploration: 4 },
      13 => { research_lab: 7, military_camp: 7, exploration: 6 },
      17 => { research_lab: 10, military_camp: 9, exploration: 8 }
    },
    guerre_electronique: {
      6  => { research_lab: 5, military_camp: 4, exploration: 4 },
      11 => { research_lab: 8, military_camp: 7, exploration: 6 }
    },
    cartographie_stellaire: {
      4 => { research_lab: 3, exploration: 2 },
      8 => { research_lab: 6, exploration: 4 }
    }
  }.freeze

  def self.for(tech_key)
    REGISTRY.fetch(tech_key.to_sym)
  end

  def self.cost_for(tech_key, level)
    REGISTRY.fetch(tech_key.to_sym)[:levels][level - 1]
  end

  def self.max_level(tech_key)
    REGISTRY.fetch(tech_key.to_sym)[:max_level]
  end

  def self.prerequisites_met?(tech_key, target_level, planet, user)
    config = REGISTRY.fetch(tech_key.to_sym)

    (config[:requires] || {}).each do |req_type, req_level|
      case req_type
      when :research_lab, :military_camp
        building_level = planet.buildings.detect { |b| b.building_type == req_type.to_s }&.level.to_i
        return false if building_level < req_level
      when :exploration
        return false if user.exploration_level < req_level
      else
        tech_level = planet.planet_technologies.detect { |pt| pt.tech_key == req_type.to_s }&.level.to_i
        return false if tech_level.to_i < req_level
      end
    end

    checkpoints = LEVEL_PREREQUISITES[tech_key.to_sym] || {}
    checkpoints.each do |min_level, prereqs|
      next if min_level > target_level
      prereqs.each do |req_type, req_level|
        case req_type
        when :research_lab, :military_camp
          building_level = planet.buildings.detect { |b| b.building_type == req_type.to_s }&.level.to_i
          return false if building_level < req_level
        when :exploration
          return false if user.exploration_level < req_level
        end
      end
    end

    true
  end
end
