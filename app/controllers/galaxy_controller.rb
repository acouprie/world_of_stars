class GalaxyController < ApplicationController
  def index
    home = Current.user.planets.includes(:buildings).find_by(is_home: true)
    @source_planet_id   = home&.id
    @has_quantum_portal = (home&.buildings&.find { |b| b.building_type == "quantum_portal" }&.level.to_i >= 1)
  end
end
