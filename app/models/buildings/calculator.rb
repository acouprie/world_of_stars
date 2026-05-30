module Buildings
  module Calculator
    module_function

    # Cost to build or upgrade to target_level.
    def cost(building_type, target_level)
      d = level_data(building_type, target_level)
      { metal: d[:metal], food: d[:food], thorium: d[:thorium] }
    end

    # Construction time in seconds for target_level.
    def construction_time(building_type, target_level)
      level_data(building_type, target_level)[:time]
    end

    # Energy produced at this level (only solar_station / nuclear_plant, 0 for all others).
    def energy_produced(building_type, level)
      return 0.0 if level == 0
      config = Buildings.find!(building_type)
      return 0.0 unless config[:energy_producer]
      level_data(building_type, level)[:production].to_f
    end

    # Total energy consumed by this building at this level (cumulative, not delta).
    def energy_consumed(building_type, level)
      return 0.0 if level == 0
      level_data(building_type, level)[:energy_consumed].to_f
    end

    # Resource production rate in units/second (production buildings only).
    # The reference data stores production in units/hour.
    def production_rate(building_type, level)
      return 0.0 if level == 0
      config = Buildings.find!(building_type)
      return 0.0 if config[:energy_producer] || config[:category] == :storage
      level_data(building_type, level)[:production].to_f / 3600.0
    end

    # Storage capacity at this level (storage buildings only, 1_000 otherwise / at level 0).
    def storage_capacity(building_type, level)
      config = Buildings.find!(building_type)
      return 1_000 unless config[:category] == :storage
      return 1_000 if level == 0
      level_data(building_type, level)[:production]
    end

    # Maximum level defined for this building type.
    def max_level(building_type)
      Buildings.find!(building_type)[:levels].size
    end

    def level_data(building_type, level)
      config = Buildings.find!(building_type)
      data   = config[:levels][level - 1]
      raise ArgumentError, "Level #{level} is not defined for #{building_type}" unless data
      data
    end
  end
end
