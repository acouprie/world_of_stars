class PlanetsController < ApplicationController
  def show
    @planet = Planet.find(params[:id])
  end

  def edit
  end

  def update
  end
end
