class ExplorationsController < ApplicationController
  def index
    @planet             = Current.user.planets.find(params[:planet_id])
    @active_missions    = @planet.exploration_missions.pending.order(:finishes_at).to_a
    @completed_missions = @planet.exploration_missions.completed.order(started_at: :desc).limit(20).to_a
  end
end
