class CombatsController < ApplicationController
  def index
    @planet             = Current.user.planets.find(params[:planet_id])
    @outgoing_traveling = @planet.combat_missions.traveling.recent.to_a
    @incoming_traveling = CombatMission.traveling.where(target_planet: @planet).to_a
    @completed_missions = CombatMission.completed.involving(@planet).recent.limit(20).to_a
    @target_planet      = Planet.find_by(id: params[:target_planet_id])
  end
end
