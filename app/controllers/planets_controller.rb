class PlanetsController < ApplicationController
  def show
    @planet = Planet.includes(:buildings, :construction_queue).find(params[:id])
  end

  def edit
  end

  def update
  end
end
