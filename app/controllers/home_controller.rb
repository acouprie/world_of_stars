class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    if authenticated?
      planet = Current.user.planets.first
      redirect_to planet_path(planet) if planet
    end
  end
end
