module ResearchHelper
  CATEGORY_COLORS = {
    energy:     "energy",
    production: "production",
    military:   "military",
    exploration: "infra",
    gate:       "quantum"
  }.freeze

  TECH_CARD_CLASSES = {
    available:   "border-border bg-space-bg-2",
    locked:      "border-border/40 bg-space-bg-2/60 opacity-70",
    researching: "border-infra/30 bg-infra/5",
    max:         "border-quantum/20 bg-quantum/5 opacity-60"
  }.freeze

  def tech_category_color(category)
    CATEGORY_COLORS[category.to_sym] || "text-muted"
  end

  def tech_card_classes(status)
    TECH_CARD_CLASSES[status.to_sym] || "border-border bg-space-bg-2"
  end
end
