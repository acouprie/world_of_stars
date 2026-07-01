module Explorations
  class MissionsController < ApplicationController
    def create
      planet        = Current.user.planets.find(params[:planet_id])
      target_planet = Planet.find(params[:target_planet_id])
      force         = parsed_force_params

      result = Explorations::StartService.call(
        planet:        planet,
        target_planet: target_planet,
        force:         force
      )

      if result.success?
        redirect_to planet_explorations_path(planet), notice: t("flash.explorations.started")
      else
        redirect_to galaxy_path, alert: t("flash.explorations.#{result.error}")
      end
    end

    private

    def parsed_force_params
      return {} unless params[:force].is_a?(ActionController::Parameters)

      Units::REGISTRY.keys.each_with_object({}) do |type, h|
        val = params[:force][type.to_s].to_i
        h[type] = val if val > 0
      end
    end
  end
end
