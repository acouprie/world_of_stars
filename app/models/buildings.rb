module Buildings
  # Per-level lookup tables — canonical source of truth for all building costs and stats.
  #
  # Fields per level:
  #   metal, food, thorium   — build cost
  #   energy_consumed        — permanent energy draw at this level (0 for storage, radar, bunker, Command Center, lab)
  #   production             — meaning varies by category:
  #                              :energy    → ⚡ produced (Integer)
  #                              :production → resource units/hour (Integer)
  #                              :storage    → storage capacity (Integer)
  #                              :military bunker → { resources: Integer, soldiers: Integer }
  #                              all others → 0
  #   time                   — construction/upgrade duration in seconds
  #
  # Categories: :energy, :production, :storage, :infrastructure, :orbital, :military
  # The :orbital category is reserved for radar_satellite (single slot on the orbital ring).
  #
  # LEVEL_PREREQUISITES (below REGISTRY) maps each building to the Command Center (or other) level
  # required to unlock each tier of levels.
  REGISTRY = {
    # ─── Energy ───────────────────────────────────────────────────────────────
    solar_station: {
      category: :energy,
      description: "Convertit l'énergie solaire",
      requires: { command_center: 1 },
      energy_producer: true,
      levels: [
        { metal: 50,    food: 25,    thorium: 0, energy_consumed: 0, production: 55,   time: 90     },
        { metal: 75,    food: 37,    thorium: 0, energy_consumed: 0, production: 108,  time: 171    },
        { metal: 112,   food: 56,    thorium: 0, energy_consumed: 0, production: 161,  time: 325    },
        { metal: 168,   food: 84,    thorium: 0, energy_consumed: 0, production: 214,  time: 617    },
        { metal: 253,   food: 126,   thorium: 0, energy_consumed: 0, production: 267,  time: 1172   },
        { metal: 379,   food: 189,   thorium: 0, energy_consumed: 0, production: 320,  time: 2228   },
        { metal: 569,   food: 284,   thorium: 0, energy_consumed: 0, production: 373,  time: 4234   },
        { metal: 854,   food: 427,   thorium: 0, energy_consumed: 0, production: 426,  time: 8045   },
        { metal: 1281,  food: 640,   thorium: 0, energy_consumed: 0, production: 479,  time: 15285  },
        { metal: 1922,  food: 961,   thorium: 0, energy_consumed: 0, production: 532,  time: 29042  },
        { metal: 2883,  food: 1441,  thorium: 0, energy_consumed: 0, production: 585,  time: 55179  },
        { metal: 4324,  food: 2162,  thorium: 0, energy_consumed: 0, production: 638,  time: 104841 },
        { metal: 6487,  food: 3243,  thorium: 0, energy_consumed: 0, production: 691,  time: 199198 }
      ]
    },
    nuclear_plant: {
      category: :energy,
      description: "Centrale à fission nucléaire",
      requires: { command_center: 5 },
      energy_producer: true,
      levels: [
        { metal: 1200,   food: 900,    thorium: 0, energy_consumed: 0, production: 119,  time: 150   },
        { metal: 2280,   food: 1710,   thorium: 0, energy_consumed: 0, production: 150,  time: 360   },
        { metal: 4332,   food: 3249,   thorium: 0, energy_consumed: 0, production: 198,  time: 617   },
        { metal: 8230,   food: 6173,   thorium: 0, energy_consumed: 0, production: 271,  time: 1103  },
        { metal: 15638,  food: 11728,  thorium: 0, energy_consumed: 0, production: 378,  time: 2030  },
        { metal: 29713,  food: 22284,  thorium: 0, energy_consumed: 0, production: 534,  time: 3789  },
        { metal: 56455,  food: 42341,  thorium: 0, energy_consumed: 0, production: 758,  time: 7132  },
        { metal: 107264, food: 80448,  thorium: 0, energy_consumed: 0, production: 1078, time: 13483 },
        { metal: 203802, food: 152852, thorium: 0, energy_consumed: 0, production: 1531, time: 25550 },
        { metal: 387225, food: 290418, thorium: 0, energy_consumed: 0, production: 2167, time: 48478 }
      ]
    },

    # ─── Production ───────────────────────────────────────────────────────────
    metal_mine: {
      category: :production,
      description: "Extraction de minerai métallique",
      requires: { command_center: 1 },
      levels: [
        { metal: 60,     food: 20,    thorium: 0, energy_consumed: 11,  production: 24,    time: 53      },
        { metal: 105,    food: 30,    thorium: 0, energy_consumed: 46,  production: 57,    time: 95      },
        { metal: 157,    food: 45,    thorium: 0, energy_consumed: 70,  production: 103,   time: 170     },
        { metal: 236,    food: 67,    thorium: 0, energy_consumed: 94,  production: 165,   time: 306     },
        { metal: 354,    food: 101,   thorium: 0, energy_consumed: 118, production: 248,   time: 551     },
        { metal: 531,    food: 151,   thorium: 0, energy_consumed: 142, production: 358,   time: 992     },
        { metal: 797,    food: 227,   thorium: 0, energy_consumed: 166, production: 501,   time: 1785    },
        { metal: 1196,   food: 341,   thorium: 0, energy_consumed: 190, production: 687,   time: 3214    },
        { metal: 1794,   food: 512,   thorium: 0, energy_consumed: 214, production: 928,   time: 5785    },
        { metal: 2691,   food: 768,   thorium: 0, energy_consumed: 238, production: 1238,  time: 10414   },
        { metal: 4036,   food: 1153,  thorium: 0, energy_consumed: 262, production: 1634,  time: 18745   },
        { metal: 6054,   food: 1729,  thorium: 0, energy_consumed: 286, production: 2139,  time: 33740   },
        { metal: 9082,   food: 2594,  thorium: 0, energy_consumed: 310, production: 2781,  time: 60734   },
        { metal: 13623,  food: 3892,  thorium: 0, energy_consumed: 334, production: 3594,  time: 109320  },
        { metal: 20435,  food: 5838,  thorium: 0, energy_consumed: 358, production: 4622,  time: 196777  },
        { metal: 30652,  food: 8757,  thorium: 0, energy_consumed: 382, production: 5916,  time: 354198  },
        { metal: 45978,  food: 13136, thorium: 0, energy_consumed: 406, production: 7543,  time: 637557  },
        { metal: 68968,  food: 19705, thorium: 0, energy_consumed: 430, production: 9584,  time: 1147604 },
        { metal: 103452, food: 29557, thorium: 0, energy_consumed: 454, production: 12140, time: 2065686 },
        { metal: 155178, food: 44336, thorium: 0, energy_consumed: 478, production: 15355, time: 3718235 }
      ]
    },
    farm: {
      category: :production,
      description: "Cultures alimentaires planétaires",
      requires: { command_center: 1 },
      levels: [
        { metal: 60,     food: 50,    thorium: 0, energy_consumed: 22,  production: 18,    time: 53      },
        { metal: 90,     food: 75,    thorium: 0, energy_consumed: 46,  production: 21,    time: 95      },
        { metal: 135,    food: 112,   thorium: 0, energy_consumed: 70,  production: 51,    time: 170     },
        { metal: 202,    food: 168,   thorium: 0, energy_consumed: 94,  production: 93,    time: 306     },
        { metal: 303,    food: 253,   thorium: 0, energy_consumed: 118, production: 149,   time: 551     },
        { metal: 405,    food: 379,   thorium: 0, energy_consumed: 142, production: 223,   time: 992     },
        { metal: 683,    food: 569,   thorium: 0, energy_consumed: 166, production: 322,   time: 1785    },
        { metal: 1025,   food: 854,   thorium: 0, energy_consumed: 190, production: 451,   time: 3214    },
        { metal: 1537,   food: 1281,  thorium: 0, energy_consumed: 214, production: 619,   time: 5785    },
        { metal: 2306,   food: 1922,  thorium: 0, energy_consumed: 238, production: 835,   time: 10414   },
        { metal: 3459,   food: 2883,  thorium: 0, energy_consumed: 262, production: 1114,  time: 18745   },
        { metal: 5189,   food: 4324,  thorium: 0, energy_consumed: 286, production: 1471,  time: 33740   },
        { metal: 7784,   food: 6487,  thorium: 0, energy_consumed: 310, production: 1925,  time: 60734   },
        { metal: 11677,  food: 9730,  thorium: 0, energy_consumed: 334, production: 2503,  time: 109320  },
        { metal: 17515,  food: 14596, thorium: 0, energy_consumed: 358, production: 3235,  time: 196777  },
        { metal: 26273,  food: 21894, thorium: 0, energy_consumed: 382, production: 4159,  time: 354198  },
        { metal: 45978,  food: 32842, thorium: 0, energy_consumed: 406, production: 5324,  time: 637557  },
        { metal: 68968,  food: 49263, thorium: 0, energy_consumed: 430, production: 6788,  time: 1147604 },
        { metal: 88673,  food: 73894, thorium: 0, energy_consumed: 454, production: 8625,  time: 2065686 },
        { metal: 133010, food: 110841,thorium: 0, energy_consumed: 478, production: 10926, time: 3718235 }
      ]
    },
    thorium_mine: {
      category: :production,
      description: "Extraction de thorium radioactif",
      requires: { command_center: 1 },
      levels: [
        { metal: 50,     food: 40,    thorium: 0, energy_consumed: 22,  production: 18,   time: 53      },
        { metal: 75,     food: 60,    thorium: 0, energy_consumed: 46,  production: 43,   time: 95      },
        { metal: 112,    food: 90,    thorium: 0, energy_consumed: 70,  production: 77,   time: 170     },
        { metal: 168,    food: 135,   thorium: 0, energy_consumed: 94,  production: 124,  time: 306     },
        { metal: 253,    food: 202,   thorium: 0, energy_consumed: 118, production: 186,  time: 551     },
        { metal: 379,    food: 303,   thorium: 0, energy_consumed: 142, production: 268,  time: 992     },
        { metal: 569,    food: 455,   thorium: 0, energy_consumed: 166, production: 376,  time: 1785    },
        { metal: 854,    food: 683,   thorium: 0, energy_consumed: 190, production: 515,  time: 3214    },
        { metal: 1281,   food: 1025,  thorium: 0, energy_consumed: 214, production: 696,  time: 5785    },
        { metal: 1922,   food: 1537,  thorium: 0, energy_consumed: 238, production: 928,  time: 10414   },
        { metal: 2883,   food: 2306,  thorium: 0, energy_consumed: 262, production: 1225, time: 18745   },
        { metal: 4324,   food: 3459,  thorium: 0, energy_consumed: 286, production: 1604, time: 33740   },
        { metal: 6487,   food: 5189,  thorium: 0, energy_consumed: 310, production: 2086, time: 60734   },
        { metal: 9730,   food: 7784,  thorium: 0, energy_consumed: 334, production: 2696, time: 109320  },
        { metal: 14596,  food: 11677, thorium: 0, energy_consumed: 358, production: 3466, time: 196777  },
        { metal: 21894,  food: 17515, thorium: 0, energy_consumed: 382, production: 4437, time: 354198  },
        { metal: 32842,  food: 26273, thorium: 0, energy_consumed: 406, production: 5657, time: 637557  },
        { metal: 49263,  food: 39410, thorium: 0, energy_consumed: 430, production: 7188, time: 1147604 },
        { metal: 73894,  food: 59115, thorium: 0, energy_consumed: 454, production: 9105, time: 2065686 },
        { metal: 110841, food: 88673, thorium: 0, energy_consumed: 478, production: 11501,time: 3718235 }
      ]
    },

    # ─── Storage ──────────────────────────────────────────────────────────────
    # production field = storage capacity at this level
    food_silo: {
      category: :storage,
      description: "Stockage de la production alimentaire",
      requires: { command_center: 1 },
      levels: [
        { metal: 65,    food: 65,    thorium: 0, energy_consumed: 0, production: 21_000,    time: 49       },
        { metal: 97,    food: 97,    thorium: 0, energy_consumed: 0, production: 28_000,    time: 92       },
        { metal: 146,   food: 146,   thorium: 0, energy_consumed: 0, production: 47_000,    time: 176      },
        { metal: 219,   food: 219,   thorium: 0, energy_consumed: 0, production: 84_000,    time: 262      },
        { metal: 329,   food: 329,   thorium: 0, energy_consumed: 0, production: 145_000,   time: 635      },
        { metal: 493,   food: 493,   thorium: 0, energy_consumed: 0, production: 236_000,   time: 1207     },
        { metal: 740,   food: 740,   thorium: 0, energy_consumed: 0, production: 363_000,   time: 2293     },
        { metal: 1110,  food: 1110,  thorium: 0, energy_consumed: 0, production: 532_000,   time: 4358     },
        { metal: 1665,  food: 1665,  thorium: 0, energy_consumed: 0, production: 749_000,   time: 8279     },
        { metal: 2498,  food: 2498,  thorium: 0, energy_consumed: 0, production: 1_020_000, time: 15731    },
        { metal: 3748,  food: 3748,  thorium: 0, energy_consumed: 0, production: 1_351_000, time: 29888    },
        { metal: 5622,  food: 5622,  thorium: 0, energy_consumed: 0, production: 1_748_000, time: 56789    },
        { metal: 8433,  food: 8433,  thorium: 0, energy_consumed: 0, production: 2_217_000, time: 107899   },
        { metal: 12650, food: 12650, thorium: 0, energy_consumed: 0, production: 2_764_000, time: 205008   },
        { metal: 18975, food: 18975, thorium: 0, energy_consumed: 0, production: 3_395_000, time: 389516   },
        { metal: 28463, food: 28463, thorium: 0, energy_consumed: 0, production: 4_116_000, time: 986773   },
        { metal: 42694, food: 42694, thorium: 0, energy_consumed: 0, production: 4_933_000, time: 1874869  },
        { metal: 64041, food: 64041, thorium: 0, energy_consumed: 0, production: 5_852_000, time: 3562251  },
        { metal: 96062, food: 96062, thorium: 0, energy_consumed: 0, production: 6_879_000, time: 6768277  },
        { metal: 144094,food: 144094,thorium: 0, energy_consumed: 0, production: 8_020_000, time: 12859727 }
      ]
    },
    metal_warehouse: {
      category: :storage,
      description: "Entrepôt de métal brut",
      requires: { command_center: 1 },
      levels: [
        { metal: 100,   food: 30,    thorium: 0, energy_consumed: 0, production: 21_000,    time: 49       },
        { metal: 150,   food: 45,    thorium: 0, energy_consumed: 0, production: 28_000,    time: 92       },
        { metal: 225,   food: 67,    thorium: 0, energy_consumed: 0, production: 47_000,    time: 176      },
        { metal: 337,   food: 101,   thorium: 0, energy_consumed: 0, production: 84_000,    time: 262      },
        { metal: 506,   food: 151,   thorium: 0, energy_consumed: 0, production: 145_000,   time: 635      },
        { metal: 759,   food: 227,   thorium: 0, energy_consumed: 0, production: 236_000,   time: 1207     },
        { metal: 1139,  food: 341,   thorium: 0, energy_consumed: 0, production: 363_000,   time: 2293     },
        { metal: 1708,  food: 512,   thorium: 0, energy_consumed: 0, production: 532_000,   time: 4358     },
        { metal: 2562,  food: 768,   thorium: 0, energy_consumed: 0, production: 749_000,   time: 8279     },
        { metal: 3844,  food: 1153,  thorium: 0, energy_consumed: 0, production: 1_020_000, time: 15731    },
        { metal: 5766,  food: 1729,  thorium: 0, energy_consumed: 0, production: 1_351_000, time: 29888    },
        { metal: 8649,  food: 2594,  thorium: 0, energy_consumed: 0, production: 1_748_000, time: 56789    },
        { metal: 12974, food: 3892,  thorium: 0, energy_consumed: 0, production: 2_217_000, time: 107899   },
        { metal: 19461, food: 5838,  thorium: 0, energy_consumed: 0, production: 2_764_000, time: 205008   },
        { metal: 29192, food: 8757,  thorium: 0, energy_consumed: 0, production: 3_395_000, time: 389516   },
        { metal: 43789, food: 13136, thorium: 0, energy_consumed: 0, production: 4_116_000, time: 986773   },
        { metal: 65684, food: 19705, thorium: 0, energy_consumed: 0, production: 4_933_000, time: 1874869  },
        { metal: 98526, food: 29557, thorium: 0, energy_consumed: 0, production: 5_852_000, time: 3562251  },
        { metal: 147789,food: 44336, thorium: 0, energy_consumed: 0, production: 6_879_000, time: 6768277  },
        { metal: 221683,food: 66505, thorium: 0, energy_consumed: 0, production: 8_020_000, time: 12859727 }
      ]
    },
    thorium_warehouse: {
      category: :storage,
      description: "Réservoir de thorium liquide",
      requires: { command_center: 1 },
      levels: [
        { metal: 30,    food: 100,   thorium: 0, energy_consumed: 0, production: 21_000,    time: 49       },
        { metal: 45,    food: 150,   thorium: 0, energy_consumed: 0, production: 28_000,    time: 92       },
        { metal: 67,    food: 225,   thorium: 0, energy_consumed: 0, production: 47_000,    time: 176      },
        { metal: 101,   food: 337,   thorium: 0, energy_consumed: 0, production: 84_000,    time: 262      },
        { metal: 151,   food: 506,   thorium: 0, energy_consumed: 0, production: 145_000,   time: 635      },
        { metal: 227,   food: 759,   thorium: 0, energy_consumed: 0, production: 236_000,   time: 1207     },
        { metal: 341,   food: 1139,  thorium: 0, energy_consumed: 0, production: 363_000,   time: 2293     },
        { metal: 512,   food: 1708,  thorium: 0, energy_consumed: 0, production: 532_000,   time: 4358     },
        { metal: 768,   food: 2562,  thorium: 0, energy_consumed: 0, production: 749_000,   time: 8279     },
        { metal: 1153,  food: 3844,  thorium: 0, energy_consumed: 0, production: 1_020_000, time: 15731    },
        { metal: 1729,  food: 5766,  thorium: 0, energy_consumed: 0, production: 1_351_000, time: 29888    },
        { metal: 2594,  food: 8649,  thorium: 0, energy_consumed: 0, production: 1_748_000, time: 56789    },
        { metal: 3892,  food: 12974, thorium: 0, energy_consumed: 0, production: 2_217_000, time: 107899   },
        { metal: 5838,  food: 19461, thorium: 0, energy_consumed: 0, production: 2_764_000, time: 205008   },
        { metal: 8757,  food: 29192, thorium: 0, energy_consumed: 0, production: 3_395_000, time: 389516   },
        { metal: 13136, food: 43789, thorium: 0, energy_consumed: 0, production: 4_116_000, time: 986773   },
        { metal: 19705, food: 65684, thorium: 0, energy_consumed: 0, production: 4_933_000, time: 1874869  },
        { metal: 29557, food: 98526, thorium: 0, energy_consumed: 0, production: 5_852_000, time: 3562251  },
        { metal: 44336, food: 147789,thorium: 0, energy_consumed: 0, production: 6_879_000, time: 6768277  },
        { metal: 66505, food: 221683,thorium: 0, energy_consumed: 0, production: 8_020_000, time: 12859727 }
      ]
    },

    # ─── Infrastructure ───────────────────────────────────────────────────────
    # Level 1 adapted by the user (cheap start, no thorium).
    # Levels 2-13 follow HEADQUARTER ratios without thorium.
    command_center: {
      category: :infrastructure,
      description: "Gère les opérations planétaires",
      requires: nil,
      levels: [
        { metal: 50,      food: 25,      thorium: 0, energy_consumed: 0, production: 0, time: 90     },
        { metal: 1260,    food: 315,     thorium: 0, energy_consumed: 0, production: 0, time: 428    },
        { metal: 2646,    food: 661,     thorium: 0, energy_consumed: 0, production: 0, time: 812    },
        { metal: 5556,    food: 1389,    thorium: 0, energy_consumed: 0, production: 0, time: 1543   },
        { metal: 11668,   food: 2917,    thorium: 0, energy_consumed: 0, production: 0, time: 2932   },
        { metal: 24504,   food: 6126,    thorium: 0, energy_consumed: 0, production: 0, time: 5571   },
        { metal: 51549,   food: 12864,   thorium: 0, energy_consumed: 0, production: 0, time: 10585  },
        { metal: 108865,  food: 27016,   thorium: 0, energy_consumed: 0, production: 0, time: 20112  },
        { metal: 226937,  food: 56734,   thorium: 0, energy_consumed: 0, production: 0, time: 38213  },
        { metal: 476568,  food: 119142,  thorium: 0, energy_consumed: 0, production: 0, time: 72605  },
        { metal: 1000792, food: 250168,  thorium: 0, energy_consumed: 0, production: 0, time: 137948 },
        { metal: 2101665, food: 525416,  thorium: 0, energy_consumed: 0, production: 0, time: 262103 },
        { metal: 4413496, food: 1103374, thorium: 0, energy_consumed: 0, production: 0, time: 434276 }
      ]
    },
    research_lab: {
      category: :infrastructure,
      description: "Développe de nouvelles technologies",
      # NOTE: exploration_level is a PLAYER stat (not a building level). The registry/
      # prerequisite checker must support this prereq type. Bootstrap intent: explore
      # first with Sondes to earn a few exploration levels, then unlock the lab, which
      # in turn unlocks the Scientifique unit and research. Value is a tunable placeholder.
      requires: { command_center: 2, exploration_level: 3 },
      levels: [
        { metal: 300,    food: 100,   thorium: 250,    energy_consumed: 0, production: 0, time: 60    },
        { metal: 600,    food: 200,   thorium: 500,    energy_consumed: 0, production: 0, time: 114   },
        { metal: 1200,   food: 400,   thorium: 1000,   energy_consumed: 0, production: 0, time: 216   },
        { metal: 2400,   food: 800,   thorium: 2000,   energy_consumed: 0, production: 0, time: 411   },
        { metal: 4800,   food: 1600,  thorium: 4000,   energy_consumed: 0, production: 0, time: 782   },
        { metal: 8000,   food: 3200,  thorium: 8000,   energy_consumed: 0, production: 0, time: 1485  },
        { metal: 16000,  food: 6400,  thorium: 16000,  energy_consumed: 0, production: 0, time: 2822  },
        { metal: 38400,  food: 12800, thorium: 32000,  energy_consumed: 0, production: 0, time: 5363  },
        { metal: 76800,  food: 25600, thorium: 64000,  energy_consumed: 0, production: 0, time: 10190 },
        { metal: 153000, food: 51200, thorium: 128000, energy_consumed: 0, production: 0, time: 19361 }
      ]
    },
    quantum_portal: {
      category: :infrastructure,
      description: "Téléportation quantique interstellaire",
      requires: { command_center: 4 },
      levels: [
        { metal: 2500,    food: 2500,    thorium: 7500,    energy_consumed: 33,  production: 0, time: 750    },
        { metal: 5000,    food: 5000,    thorium: 15000,   energy_consumed: 68,  production: 0, time: 1500   },
        { metal: 10000,   food: 10000,   thorium: 30000,   energy_consumed: 103, production: 0, time: 3000   },
        { metal: 20000,   food: 20000,   thorium: 60000,   energy_consumed: 138, production: 0, time: 6000   },
        { metal: 40000,   food: 40000,   thorium: 120000,  energy_consumed: 173, production: 0, time: 12000  },
        { metal: 80000,   food: 80000,   thorium: 240000,  energy_consumed: 208, production: 0, time: 24000  },
        { metal: 160000,  food: 160000,  thorium: 480000,  energy_consumed: 243, production: 0, time: 48000  },
        { metal: 320000,  food: 320000,  thorium: 960000,  energy_consumed: 278, production: 0, time: 96000  },
        { metal: 640000,  food: 640000,  thorium: 1920000, energy_consumed: 313, production: 0, time: 192000 },
        { metal: 1280000, food: 1280000, thorium: 3840000, energy_consumed: 348, production: 0, time: 348000 }
      ]
    },
    radar_satellite: {
      category: :orbital,
      description: "Détection et surveillance orbitale",
      requires: { command_center: 3 },
      # No energy_consumed — runs on dedicated solar panels.
      # Each level unlocks additional detection capabilities:
      #   1 → fleet presence in orbit
      #   2 → owner pseudo
      #   3 → full orbit fleet composition
      #   4 → incoming fleet detected
      #   5 → incoming fleet owner pseudo
      #   6 → approximate distance (far/close/imminent)
      #   7 → ~35% of incoming composition revealed
      #   8 → ~65% of incoming composition revealed
      #   9 → ~85% of incoming composition revealed
      #  10 → 100% of incoming-fleet composition revealed; applies ONLY to fleets incoming to this planet (not the galaxy map or other players' planets) (requires Command Center level 11)
      levels: [
        { metal: 8_000,     food: 8_000,     thorium: 16_000,    energy_consumed: 0, production: 0, time: 90     },
        { metal: 16_000,    food: 16_000,    thorium: 32_000,    energy_consumed: 0, production: 0, time: 171    },
        { metal: 32_000,    food: 32_000,    thorium: 64_000,    energy_consumed: 0, production: 0, time: 325    },
        { metal: 64_000,    food: 64_000,    thorium: 128_000,   energy_consumed: 0, production: 0, time: 617    },
        { metal: 128_000,   food: 128_000,   thorium: 256_000,   energy_consumed: 0, production: 0, time: 1_172  },
        { metal: 256_000,   food: 256_000,   thorium: 512_000,   energy_consumed: 0, production: 0, time: 2_228  },
        { metal: 512_000,   food: 512_000,   thorium: 1_024_000, energy_consumed: 0, production: 0, time: 4_234  },
        { metal: 1_024_000, food: 1_024_000, thorium: 2_048_000, energy_consumed: 0, production: 0, time: 8_045  },
        { metal: 2_048_000, food: 2_048_000, thorium: 4_096_000, energy_consumed: 0, production: 0, time: 15_285 },
        { metal: 4_096_000, food: 4_096_000, thorium: 8_192_000, energy_consumed: 0, production: 0, time: 29_042 }
      ]
    },

    # ─── Military ─────────────────────────────────────────────────────────────
    training_camp: {
      category: :military,
      description: "Entraîne les unités de combat",
      requires: { command_center: 1 },
      # energy_consumed increases by ~15 per level (20 → 150).
      # Reduces unit FORMATION TIME as it levels up; does NOT unlock unit types.
      # Unit types are unlocked by military_camp (which also gates some military techs).
      levels: [
        { metal: 250,   food: 250,   thorium: 100,   energy_consumed: 20,  production: 0, time: 45    },
        { metal: 500,   food: 500,   thorium: 128,   energy_consumed: 35,  production: 0, time: 86    },
        { metal: 1000,  food: 1000,  thorium: 400,   energy_consumed: 50,  production: 0, time: 162   },
        { metal: 1344,  food: 1344,  thorium: 800,   energy_consumed: 65,  production: 0, time: 308   },
        { metal: 2688,  food: 4000,  thorium: 1024,  energy_consumed: 80,  production: 0, time: 1114  },
        { metal: 5376,  food: 5376,  thorium: 2048,  energy_consumed: 95,  production: 0, time: 2030  },
        { metal: 10752, food: 10752, thorium: 4092,  energy_consumed: 110, production: 0, time: 2717  },
        { metal: 21504, food: 21504, thorium: 8192,  energy_consumed: 125, production: 0, time: 4022  },
        { metal: 43008, food: 43008, thorium: 16384, energy_consumed: 135, production: 0, time: 7646  },
        { metal: 86016, food: 86016, thorium: 32768, energy_consumed: 150, production: 0, time: 14521 }
      ]
    },
    military_camp: {
      category: :military,
      description: "Caserne pour les troupes terrestres",
      requires: { command_center: 2 },
      # energy_consumed increases by ~20 per level (30 → 200).
      levels: [
        { metal: 300,    food: 200,    thorium: 150,   energy_consumed: 30,  production: 0, time: 45    },
        { metal: 600,    food: 400,    thorium: 300,   energy_consumed: 50,  production: 0, time: 86    },
        { metal: 1200,   food: 800,    thorium: 600,   energy_consumed: 70,  production: 0, time: 162   },
        { metal: 2400,   food: 1600,   thorium: 1200,  energy_consumed: 90,  production: 0, time: 308   },
        { metal: 4800,   food: 3200,   thorium: 2400,  energy_consumed: 110, production: 0, time: 1114  },
        { metal: 9600,   food: 6400,   thorium: 4800,  energy_consumed: 130, production: 0, time: 2030  },
        { metal: 19200,  food: 12800,  thorium: 9600,  energy_consumed: 155, production: 0, time: 2717  },
        { metal: 38400,  food: 25600,  thorium: 19200, energy_consumed: 175, production: 0, time: 4022  },
        { metal: 76800,  food: 51200,  thorium: 38400, energy_consumed: 185, production: 0, time: 7646  },
        { metal: 153600, food: 102400, thorium: 76800, energy_consumed: 200, production: 0, time: 14521 }
      ]
    },
    ship_factory: {
      category: :military,
      description: "Construction de vaisseaux spatiaux",
      requires: { command_center: 3 },
      # energy_consumed increases by ~40 per level (50 → 600).
      # Most thorium-intensive military building by design.
      levels: [
        { metal: 250,     food: 100,     thorium: 320,     energy_consumed: 50,  production: 0, time: 60     },
        { metal: 500,     food: 200,     thorium: 640,     energy_consumed: 90,  production: 0, time: 114    },
        { metal: 1000,    food: 400,     thorium: 1280,    energy_consumed: 130, production: 0, time: 216    },
        { metal: 2000,    food: 800,     thorium: 2560,    energy_consumed: 165, production: 0, time: 411    },
        { metal: 4000,    food: 1600,    thorium: 5120,    energy_consumed: 205, production: 0, time: 782    },
        { metal: 8000,    food: 3200,    thorium: 10240,   energy_consumed: 245, production: 0, time: 1485   },
        { metal: 16000,   food: 6400,    thorium: 20480,   energy_consumed: 285, production: 0, time: 2822   },
        { metal: 32000,   food: 12800,   thorium: 40960,   energy_consumed: 325, production: 0, time: 5363   },
        { metal: 64000,   food: 25600,   thorium: 81920,   energy_consumed: 365, production: 0, time: 10190  },
        { metal: 128000,  food: 51200,   thorium: 163840,  energy_consumed: 405, production: 0, time: 19361  },
        { metal: 256000,  food: 102400,  thorium: 327680,  energy_consumed: 445, production: 0, time: 36786  },
        { metal: 512000,  food: 204000,  thorium: 655360,  energy_consumed: 480, production: 0, time: 69894  },
        { metal: 1024000, food: 409600,  thorium: 1310720, energy_consumed: 520, production: 0, time: 132799 },
        { metal: 2048000, food: 819200,  thorium: 2621440, energy_consumed: 560, production: 0, time: 216317 },
        { metal: 4096000, food: 1638400, thorium: 5242880, energy_consumed: 600, production: 0, time: 479404 }
      ]
    },
    bunker: {
      category: :military,
      description: "Abri de protection des ressources",
      requires: { command_center: 2 },
      # production is a Hash: { resources: Integer, soldiers: Integer }
      #   resources → total shared capacity across metal + food + thorium (player allocates freely)
      #   soldiers  → max units protected regardless of type
      # Protection deliberately slows above level 6 so late-game risk stays meaningful.
      levels: [
        { metal: 1000,   food: 1000,   thorium: 3000,    energy_consumed: 0, production: { resources: 5_000,   soldiers: 50     }, time: 90    },
        { metal: 2000,   food: 2000,   thorium: 6000,    energy_consumed: 0, production: { resources: 12_000,  soldiers: 120    }, time: 171   },
        { metal: 4000,   food: 4000,   thorium: 12000,   energy_consumed: 0, production: { resources: 25_000,  soldiers: 250    }, time: 325   },
        { metal: 8000,   food: 8000,   thorium: 24000,   energy_consumed: 0, production: { resources: 50_000,  soldiers: 500    }, time: 617   },
        { metal: 16000,  food: 16000,  thorium: 48000,   energy_consumed: 0, production: { resources: 100_000, soldiers: 1_000  }, time: 1172  },
        { metal: 32000,  food: 32000,  thorium: 96000,   energy_consumed: 0, production: { resources: 175_000, soldiers: 2_000  }, time: 2228  },
        { metal: 64000,  food: 64000,  thorium: 192000,  energy_consumed: 0, production: { resources: 275_000, soldiers: 4_000  }, time: 4234  },
        { metal: 128000, food: 128000, thorium: 348000,  energy_consumed: 0, production: { resources: 375_000, soldiers: 7_000  }, time: 8045  },
        { metal: 256000, food: 256000, thorium: 768000,  energy_consumed: 0, production: { resources: 450_000, soldiers: 12_000 }, time: 15288 },
        { metal: 512000, food: 512000, thorium: 1536000, energy_consumed: 0, production: { resources: 500_000, soldiers: 20_000 }, time: 29042 }
      ]
    }
  }.freeze

  # Maps each building to the prerequisites required per level tier, in a compact threshold format.
  # Format: { building_key => { min_building_level => { prereq_type => min_prereq_level } } }
  #
  # For a target level N, find the highest key ≤ N — those are the active prerequisites.
  # Extensible: add other building types or future technology keys alongside :command_center.
  #
  # Example:
  #   Buildings.prerequisites_for(:solar_station, 4)  # => { command_center: 3 }
  #   Buildings.prerequisites_for(:ship_factory, 7)   # => { command_center: 5 }
  LEVEL_PREREQUISITES = {
    solar_station:     { 1 => { command_center: 1 }, 4 => { command_center: 3 }, 7 => { command_center: 5 }, 10 => { command_center: 8 }, 13 => { command_center: 10 } },
    nuclear_plant:     { 1 => { command_center: 5 }, 5 => { command_center: 7 }, 10 => { command_center: 10 } },
    metal_mine:        { 1 => { command_center: 1 }, 4 => { command_center: 2 }, 6 => { command_center: 3 }, 9 => { command_center: 5 }, 13 => { command_center: 7 }, 16 => { command_center: 10 }, 19 => { command_center: 13 } },
    farm:              { 1 => { command_center: 1 }, 4 => { command_center: 2 }, 6 => { command_center: 3 }, 9 => { command_center: 5 }, 13 => { command_center: 7 }, 16 => { command_center: 10 }, 19 => { command_center: 13 } },
    thorium_mine:      { 1 => { command_center: 1 }, 4 => { command_center: 2 }, 6 => { command_center: 3 }, 9 => { command_center: 5 }, 13 => { command_center: 7 }, 16 => { command_center: 10 }, 19 => { command_center: 13 } },
    food_silo:         { 1 => { command_center: 1 }, 4 => { command_center: 2 }, 7 => { command_center: 4 }, 11 => { command_center: 7 }, 16 => { command_center: 10 } },
    metal_warehouse:   { 1 => { command_center: 1 }, 4 => { command_center: 2 }, 7 => { command_center: 4 }, 11 => { command_center: 7 }, 16 => { command_center: 10 } },
    thorium_warehouse: { 1 => { command_center: 1 }, 4 => { command_center: 2 }, 7 => { command_center: 4 }, 11 => { command_center: 7 }, 16 => { command_center: 10 } },
    research_lab:      { 1 => { command_center: 2 }, 4 => { command_center: 4 }, 7 => { command_center: 6 }, 9 => { command_center: 9 } },
    quantum_portal:    { 1 => { command_center: 4 }, 5 => { command_center: 6 }, 9 => { command_center: 9 } },
    radar_satellite:   { 1 => { command_center: 3 }, 4 => { command_center: 5 }, 7 => { command_center: 8 }, 10 => { command_center: 11 } },
    training_camp:     { 1 => { command_center: 1 }, 3 => { command_center: 3 }, 6 => { command_center: 6 }, 9 => { command_center: 9 } },
    military_camp:     { 1 => { command_center: 2 }, 4 => { command_center: 4 }, 7 => { command_center: 7 }, 10 => { command_center: 10 } },
    ship_factory:      { 1 => { command_center: 3 }, 5 => { command_center: 5 }, 8 => { command_center: 8 }, 11 => { command_center: 11 } },
    bunker:            { 1 => { command_center: 2 }, 4 => { command_center: 4 }, 7 => { command_center: 7 }, 10 => { command_center: 10 } },
    # command_center has no prerequisites — absent from this table
  }.freeze

  # ─── Helpers ──────────────────────────────────────────────────────────────

  def self.orbital?(building_type)
    REGISTRY[building_type.to_sym]&.fetch(:category, nil) == :orbital
  end

  def self.find!(type)
    REGISTRY.fetch(type.to_sym) { raise ArgumentError, "Unknown building type: #{type}" }
  end

  # Returns the prerequisites hash for upgrading a building to the given level.
  # Uses threshold lookup: finds the highest tier key ≤ building_level.
  # Returns {} for command_center or any building with no defined prerequisites.
  def self.prerequisites_for(building_type, building_level)
    thresholds = LEVEL_PREREQUISITES[building_type.to_sym]
    return {} unless thresholds
    key = thresholds.keys.select { |l| l <= building_level }.max
    key ? thresholds[key] : {}
  end

  # Converts LEVEL_PREREQUISITES into a flat { building_level => cc_level } map per building,
  # suitable for the buildings-explorer JS controller (which only renders Command Center prerequisites).
  # Non-Command Center prerequisites (other buildings, future technologies) are intentionally ignored here —
  # they will need their own display mechanism when implemented.
  def self.cc_requirements
    LEVEL_PREREQUISITES.each_with_object({}) do |(building, thresholds), result|
      max_level = REGISTRY.dig(building, :levels)&.length || 0
      sorted = thresholds.sort_by { |level, _| level }
      flat = {}
      sorted.each_with_index do |(min_level, prereq), i|
        cc_level = prereq[:command_center]
        next unless cc_level  # skip thresholds that have no Command Center prerequisite
        next_min = sorted[i + 1]&.first || (max_level + 1)
        (min_level...next_min).each { |l| flat[l] = cc_level }
      end
      result[building] = flat unless flat.empty?
    end
  end
end