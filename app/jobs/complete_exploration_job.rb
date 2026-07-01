class CompleteExplorationJob < ApplicationJob
  queue_as :default

  def perform(mission_id)
    mission = ExplorationMission.find_by(id: mission_id)
    return unless mission&.status == "pending"

    mission.planet.with_lock do
      mission.reload
      return unless mission.status == "pending"

      carto_level = mission.planet
                           .planet_technologies
                           .find_by(tech_key: "cartographie_stellaire")
                           &.level.to_i

      result = Explorations::Resolver.new(
        mission.force_snapshot,
        carto_level: carto_level,
        seed:        mission.id
      ).call

      mission.update!(
        status:             "completed",
        exploration_points: result.exploration_points,
        metal_gained:       result.resources[:metal],
        food_gained:        result.resources[:food],
        thorium_gained:     result.resources[:thorium],
        losses_snapshot:    result.losses
      )

      mission.planet.user.increment!(:exploration_xp, result.exploration_points)

      survivors = compute_survivors(mission.force_snapshot, result.losses)
      survivors.each do |type_str, count|
        next if count <= 0
        unit = mission.planet.units.find_or_initialize_by(unit_type: type_str)
        unit.count = (unit.count || 0) + count
        unit.save!
      end

      planet = mission.planet
      planet.calculate_resources!
      planet.metal_stock   = [planet.metal_stock   + result.resources[:metal],   planet.metal_capacity].min
      planet.food_stock    = [planet.food_stock    + result.resources[:food],    planet.food_capacity].min
      planet.thorium_stock = [planet.thorium_stock + result.resources[:thorium], planet.thorium_capacity].min
      planet.save!
    end
  end

  private

  def compute_survivors(force_snapshot, losses)
    force_snapshot.each_with_object({}) do |(type_str, sent), acc|
      lost = losses.fetch(type_str, losses.fetch(type_str.to_sym, 0))
      acc[type_str] = [sent - lost, 0].max
    end
  end
end
