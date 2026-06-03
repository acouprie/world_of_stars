class PlanetsController < ApplicationController
  before_action :set_planet

  def show
  end

  def edit
  end

  def update
  end

  private

  def set_planet
    @planet = Current.user.planets
                          .includes(:buildings, construction_queue: :building)
                          .find(params[:id])
  end
end
