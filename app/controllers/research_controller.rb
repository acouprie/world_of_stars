class ResearchController < ApplicationController
  CATEGORY_ORDER = %i[energy production military exploration gate].freeze

  before_action :set_planet

  def index
    @user         = Current.user
    @active_queue = @planet.research_queues.pending.first
    @techs_by_category = build_techs_by_category
  end

  private

  def set_planet
    @planet = Current.user.planets
                          .includes(:buildings, :planet_technologies, :research_queues)
                          .find(params[:planet_id])
  end

  def build_techs_by_category
    tech_map = @planet.planet_technologies.each_with_object({}) do |pt, h|
      h[pt.tech_key.to_sym] = pt
    end

    grouped = {}
    Technologies::REGISTRY.each do |tech_key, config|
      planet_tech   = tech_map[tech_key]
      current_level = planet_tech&.level || 0
      max_level     = config[:max_level]
      at_max        = current_level >= max_level
      is_researching = planet_tech&.researching? || false
      target_level  = current_level + 1

      prereqs_ok   = at_max ? true : Technologies.prerequisites_met?(tech_key, target_level, @planet, @user)
      next_cost    = at_max ? nil : Technologies.cost_for(tech_key, target_level)
      can_afford   = next_cost.nil? ? false : can_afford_cost?(next_cost)

      status = if at_max
                 :max
               elsif is_researching
                 :researching
               elsif !prereqs_ok
                 :locked
               else
                 :available
               end

      category = config[:category]
      grouped[category] ||= []
      grouped[category] << {
        key:           tech_key,
        config:        config,
        current_level: current_level,
        max_level:     max_level,
        status:        status,
        next_cost:     next_cost,
        can_afford:    can_afford
      }
    end

    CATEGORY_ORDER.filter_map { |cat| [cat, grouped[cat]] if grouped.key?(cat) }.to_h
  end

  def can_afford_cost?(cost)
    @planet.metal_stock.to_f    >= cost[:metal].to_f &&
      @planet.food_stock.to_f   >= cost[:food].to_f &&
      @planet.thorium_stock.to_f >= cost[:thorium].to_f
  end
end
