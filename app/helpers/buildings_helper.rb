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
    energy:         "text-energy",
    production:     "text-production",
    storage:        "text-storage",
    infrastructure: "text-infra",
    orbital:        "text-orbital",
    military:       "text-military"
  }.freeze

  CATEGORY_BADGE_CLASSES = {
    energy:         "border-energy/30 bg-energy/10 text-energy",
    production:     "border-production/30 bg-production/10 text-production",
    storage:        "border-storage/30 bg-storage/10 text-storage",
    infrastructure: "border-infra/30 bg-infra/10 text-infra",
    orbital:        "border-orbital/30 bg-orbital/10 text-orbital",
    military:       "border-military/30 bg-military/10 text-military"
  }.freeze

  CATEGORY_CARD_CLASSES = {
    energy:         "border-energy/20 hover:border-energy/60",
    production:     "border-production/20 hover:border-production/60",
    storage:        "border-storage/20 hover:border-storage/60",
    infrastructure: "border-infra/20 hover:border-infra/60",
    orbital:        "border-orbital/20 hover:border-orbital/60",
    military:       "border-military/20 hover:border-military/60"
  }.freeze

  CATEGORY_TAB_CLASSES = {
    energy:         "hover:border-energy hover:text-energy data-[active=true]:border-energy data-[active=true]:bg-energy/10 data-[active=true]:text-energy",
    production:     "hover:border-production hover:text-production data-[active=true]:border-production data-[active=true]:bg-production/10 data-[active=true]:text-production",
    storage:        "hover:border-storage hover:text-storage data-[active=true]:border-storage data-[active=true]:bg-storage/10 data-[active=true]:text-storage",
    infrastructure: "hover:border-infra hover:text-infra data-[active=true]:border-infra data-[active=true]:bg-infra/10 data-[active=true]:text-infra",
    orbital:        "hover:border-orbital hover:text-orbital data-[active=true]:border-orbital data-[active=true]:bg-orbital/10 data-[active=true]:text-orbital",
    military:       "hover:border-military hover:text-military data-[active=true]:border-military data-[active=true]:bg-military/10 data-[active=true]:text-military"
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

  def building_category_tab_classes(category)
    CATEGORY_TAB_CLASSES[category.to_sym] || "hover:border-primary hover:text-primary data-[active=true]:border-primary data-[active=true]:bg-primary/10 data-[active=true]:text-primary"
  end

  def building_category_card_classes(type)
    cat = Buildings::REGISTRY[type.to_sym]&.dig(:category)
    CATEGORY_CARD_CLASSES[cat] || "border-border hover:border-primary/50"
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

  def building_description(type)
    I18n.t("buildings.descriptions.#{type}", default: "")
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
