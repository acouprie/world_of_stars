module BuildingsHelper
  BUILDING_ICONS = {
    "solar_station"     => "☀",
    "nuclear_plant"     => "☢",
    "metal_mine"        => "⛏",
    "farm"              => "✿",
    "thorium_mine"      => "◇",
    "food_silo"         => "▲",
    "metal_warehouse"   => "□",
    "thorium_warehouse" => "◆",
    "command_center"    => "★",
    "research_lab"      => "⊕",
    "quantum_portal"    => "◎",
    "radar_satellite"   => "⊙",
    "training_camp"     => "⚑",
    "military_camp"     => "✦",
    "ship_factory"      => "▷",
    "bunker"            => "⬢"
  }.freeze

  CATEGORY_TEXT_CLASSES = {
    energy:         "text-primary",
    production:     "text-secondary",
    storage:        "text-text-muted",
    infrastructure: "text-secondary",
    orbital:        "text-quantum",
    military:       "text-varek"
  }.freeze

  CATEGORY_BADGE_CLASSES = {
    energy:         "border-primary/30 bg-primary/10 text-primary",
    production:     "border-secondary/30 bg-secondary/10 text-secondary",
    storage:        "border-border bg-surface text-text-muted",
    infrastructure: "border-secondary/30 bg-secondary/10 text-secondary",
    orbital:        "border-quantum/30 bg-quantum/10 text-quantum",
    military:       "border-varek/30 bg-varek/10 text-varek"
  }.freeze

  PRODUCTION_RESOURCE_KEYS = {
    "metal_mine"        => "metal",
    "farm"              => "food",
    "thorium_mine"      => "thorium"
  }.freeze

  STORAGE_RESOURCE_KEYS = {
    "food_silo"         => "food",
    "metal_warehouse"   => "metal",
    "thorium_warehouse" => "thorium"
  }.freeze

  def building_icon(type)
    BUILDING_ICONS[type.to_s] || "?"
  end

  def building_category_color_class(type)
    cat = Buildings::REGISTRY[type.to_sym]&.dig(:category)
    CATEGORY_TEXT_CLASSES[cat] || "text-text-muted"
  end

  def building_category_badge_classes(type)
    cat = Buildings::REGISTRY[type.to_sym]&.dig(:category)
    CATEGORY_BADGE_CLASSES[cat] || "border-border bg-surface text-text-muted"
  end

  def building_production_info(building)
    return nil if building.level < 1

    config = building.config
    level_data = config[:levels][building.level - 1]
    production = level_data&.dig(:production)

    case config[:category]
    when :energy
      return nil unless production.to_i > 0
      t("planets.show.buildings_list.energy_output",
        value: number_with_delimiter(production.to_i),
        resource: t("resources.energy").downcase)
    when :production
      resource_key = PRODUCTION_RESOURCE_KEYS[building.building_type]
      return nil unless resource_key && production.to_i > 0
      t("planets.show.buildings_list.production_rate",
        value: number_with_delimiter(production),
        resource: t("resources.#{resource_key}").downcase)
    when :storage
      resource_key = STORAGE_RESOURCE_KEYS[building.building_type]
      return nil unless resource_key && production.to_i > 0
      t("planets.show.buildings_list.storage_capacity",
        value: number_with_delimiter(production),
        resource: t("resources.#{resource_key}").downcase)
    when :military
      return nil unless production.is_a?(Hash)
      t("planets.show.buildings_list.bunker_capacity",
        resources: number_with_delimiter(production[:resources]),
        soldiers: number_with_delimiter(production[:soldiers]))
    end
  end

  def building_name(type)
    I18n.t("buildings.types.#{type}", default: type.to_s.humanize)
  end

  def format_duration(seconds)
    seconds = seconds.to_i
    if seconds < 60
      "#{seconds} s"
    elsif seconds < 3600
      m = seconds / 60
      s = seconds % 60
      s > 0 ? "#{m} min #{s} s" : "#{m} min"
    else
      h = seconds / 3600
      m = (seconds % 3600) / 60
      m > 0 ? "#{h} h #{m} min" : "#{h} h"
    end
  end
end
