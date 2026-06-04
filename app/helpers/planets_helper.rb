module PlanetsHelper
  SLOT_POSITIONS = [
    { slot_index: 0,  position_x: 0.82, position_y: 0.15, is_orbital: true  },  # orbital (radar satellite)
    { slot_index: 1,  position_x: 0.35, position_y: 0.25, is_orbital: false },
    { slot_index: 2,  position_x: 0.60, position_y: 0.22, is_orbital: false },
    { slot_index: 3,  position_x: 0.72, position_y: 0.42, is_orbital: false },
    { slot_index: 4,  position_x: 0.65, position_y: 0.62, is_orbital: false },
    { slot_index: 5,  position_x: 0.48, position_y: 0.72, is_orbital: false },
    { slot_index: 6,  position_x: 0.30, position_y: 0.65, is_orbital: false },
    { slot_index: 7,  position_x: 0.22, position_y: 0.45, is_orbital: false },
    { slot_index: 8,  position_x: 0.28, position_y: 0.30, is_orbital: false },
    { slot_index: 9,  position_x: 0.50, position_y: 0.48, is_orbital: false },
    { slot_index: 10, position_x: 0.68, position_y: 0.30, is_orbital: false },
    { slot_index: 11, position_x: 0.40, position_y: 0.55, is_orbital: false },
    { slot_index: 12, position_x: 0.48, position_y: 0.28, is_orbital: false },
    { slot_index: 13, position_x: 0.32, position_y: 0.52, is_orbital: false },
    { slot_index: 14, position_x: 0.60, position_y: 0.52, is_orbital: false },
    { slot_index: 15, position_x: 0.55, position_y: 0.65, is_orbital: false },
  ].freeze

  def orbital_view_props(planet)
    buildings = planet.buildings
    cq        = planet.construction_queue
    active_cq = cq&.pending? ? cq : nil
    occupied   = buildings.pluck(:slot_index).compact

    buildings_data = buildings.map do |b|
      slot = SLOT_POSITIONS.find { |s| s[:slot_index] == b.slot_index }
      {
        id:            b.id,
        building_type: b.building_type,
        level:         b.level,
        in_progress:   active_cq&.building_id == b.id,
        position_x:    slot ? slot[:position_x] : 0.5,
        position_y:    slot ? slot[:position_y] : 0.5,
        is_orbital:    slot ? slot[:is_orbital] : false,
      }
    end

    slots_data = SLOT_POSITIONS
      .reject { |s| occupied.include?(s[:slot_index]) }
      .map    { |s| { slot_index: s[:slot_index], position_x: s[:position_x], position_y: s[:position_y], is_orbital: s[:is_orbital] } }

    {
      planet: {
        id:          planet.id,
        name:        planet.name,
        coords:      "[#{planet.coord_x} : #{planet.coord_y}]",
        is_home:     planet.is_home,
        biome: planet.biome,
      },
      buildings:               buildings_data,
      slots:                   slots_data,
      available_building_types: planet.available_building_types.map(&:to_s),
      i18n: {
        slot_orbital: I18n.t("planets.orbital_view.slot_orbital"),
        slot_empty:   I18n.t("planets.orbital_view.slot_empty"),
        no_buildings: I18n.t("planets.orbital_view.no_buildings"),
        home_badge:   I18n.t("planets.orbital_view.home_badge"),
        building_labels: Buildings::REGISTRY.keys.each_with_object({}) do |k, h|
          h[k.to_s] = I18n.t("buildings.types.#{k}")
        end,
      },
    }
  end
end
