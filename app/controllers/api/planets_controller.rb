module Api
  class PlanetsController < ApplicationController
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
