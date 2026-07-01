module Api
  class PlanetsController < ApplicationController
    def exploration_readiness
      planet = Current.user.planets.includes(:units).find(params[:id])
      units  = Units::REGISTRY.filter_map do |type, config|
        unit  = planet.units.find { |u| u.unit_type == type.to_s }
        count = unit&.count.to_i
        next if count <= 0
        { type: type.to_s, name: I18n.t("units.types.#{type}"), category: config[:category].to_s, count: count }
      end
      active_count = planet.exploration_missions.pending.count
      render json: {
        units:           units,
        active_missions: active_count,
        max_missions:    Explorations::MAX_SIMULTANEOUS_EXPLORATIONS,
        can_launch:      active_count < Explorations::MAX_SIMULTANEOUS_EXPLORATIONS
      }
    end

    def index
      planets = Planet.includes(:user).all
      render json: {
        current_user_id: Current.user.id,
        planets: planets.map { |p|
          {
            id: p.id,
            name: p.name,
            coord_x: p.coord_x,
            coord_y: p.coord_y,
            biome: p.biome,
            planet_type: p.planet_type,
            is_home: p.is_home,
            user_id: p.user_id,
            user_name: p.user&.username,
          }
        },
      }
    end
  end
end
