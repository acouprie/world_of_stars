module UnitsHelper
  UNIT_ICONS = {
    "maraudeur"    => "✕",
    "regulier"     => "✚",
    "sentinelle"   => "⬡",
    "scientifique" => "⊛",
    "sonde"        => "◉",
    "spectre"      => "◈",
    "mule"         => "⊡"
  }.freeze

  CATEGORY_TEXT_CLASSES = {
    combat:         "text-military",
    exploration:    "text-infra",
    reconnaissance: "text-orbital",
    transport:      "text-storage"
  }.freeze

  CATEGORY_BADGE_CLASSES = {
    combat:         "border-military/30 bg-military/10 text-military",
    exploration:    "border-infra/30 bg-infra/10 text-infra",
    reconnaissance: "border-orbital/30 bg-orbital/10 text-orbital",
    transport:      "border-storage/30 bg-storage/10 text-storage"
  }.freeze

  def unit_icon(type)
    UNIT_ICONS[type.to_s] || "?"
  end

  def unit_name(type)
    I18n.t("units.types.#{type}", default: type.to_s.humanize)
  end

  def unit_category_color_class(type)
    cat = Units::REGISTRY[type.to_sym]&.dig(:category)
    CATEGORY_TEXT_CLASSES[cat] || "text-text-muted"
  end

  def unit_category_badge_classes(type)
    cat = Units::REGISTRY[type.to_sym]&.dig(:category)
    CATEGORY_BADGE_CLASSES[cat] || "border-border bg-surface text-text-muted"
  end

  def building_name_for_requires(key)
    I18n.t("buildings.types.#{key}", default: key.to_s.humanize)
  end

  def technology_name_for_requires(key)
    I18n.t("technologies.names.#{key}", default: key.to_s.humanize)
  end
end
