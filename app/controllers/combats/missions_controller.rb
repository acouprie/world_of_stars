module Combats
  class MissionsController < ApplicationController
    def create
      planet        = Current.user.planets.find(params[:planet_id])
      target_planet = Planet.find(params[:target_planet_id])

      result = Combats::StartService.call(
        planet:        planet,
        target_planet: target_planet,
        force:         parsed_force_params
      )

      if result.success?
        outgoing = planet.combat_missions.traveling.recent.to_a
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace("resources_bar", partial: "planets/resources_bar", locals: { planet: planet.reload }),
              turbo_stream.replace("outgoing-missions-section", partial: "combats/outgoing_missions_section", locals: { outgoing_traveling: outgoing }),
              turbo_stream.prepend("flash-messages", partial: "layouts/flash_notice", locals: { message: t("flash.combats.started") }),
            ]
          end
          format.html { redirect_to planet_combats_path(planet), notice: t("flash.combats.started") }
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.prepend(
              "flash-messages",
              partial: "layouts/flash_alert",
              locals: { message: t("flash.combats.#{result.error}", default: result.error) }
            )
          end
          format.html { redirect_to planet_combats_path(planet), alert: t("flash.combats.#{result.error}", default: result.error) }
        end
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
