class CompleteCombatJob < ApplicationJob
  queue_as :default

  def perform(combat_mission_id)
    mission = CombatMission.find_by(id: combat_mission_id)
    return unless mission&.status == "traveling"

    source, target = [mission.planet, mission.target_planet].sort_by(&:id)

    ActiveRecord::Base.transaction do
      source.lock!
      target.lock!

      mission.reload
      return unless mission.status == "traveling"

      source = mission.planet
      target = mission.target_planet

      attacker_force = mission.attacker_force.transform_keys(&:to_sym)
      defender_force = target.units
                             .where("count > 0")
                             .pluck(:unit_type, :count)
                             .to_h
                             .transform_keys(&:to_sym)

      context = {
        seed:          mission.id,
        assault_kind:  :portal,
        attacker_tech: read_combat_techs(source),
        defender_tech: read_combat_techs(target)
      }

      result = Combats::Resolver.new(attacker_force, defender_force, context).call

      metal_pillaged = food_pillaged = thorium_pillaged = 0

      if result.outcome == :attacker_wins
        transport_cap = result.pillage_capacity
        target.calculate_resources!
        metal_pillaged   = [target.metal_stock,   transport_cap / 3].min
        food_pillaged    = [target.food_stock,    transport_cap / 3].min
        thorium_pillaged = [target.thorium_stock, transport_cap / 3].min
        target.metal_stock   -= metal_pillaged
        target.food_stock    -= food_pillaged
        target.thorium_stock -= thorium_pillaged
        target.save!

        source.calculate_resources!
        source.metal_stock   = [source.metal_stock   + metal_pillaged,   source.metal_capacity].min
        source.food_stock    = [source.food_stock    + food_pillaged,    source.food_capacity].min
        source.thorium_stock = [source.thorium_stock + thorium_pillaged, source.thorium_capacity].min
        source.save!
      end

      attacker_xp = result.xp[:attacker].round
      defender_xp = result.xp[:defender].round

      apply_losses(target, result.losses[:defender])
      restitute_survivors(source, attacker_force, result.losses[:attacker])

      source.user.increment!(:combat_xp, attacker_xp)   if attacker_xp > 0
      target.user&.increment!(:combat_xp, defender_xp) if defender_xp > 0

      mission.update!(
        status:                  "completed",
        defender_force_snapshot: defender_force.transform_keys(&:to_s),
        outcome:                 result.outcome.to_s,
        attacker_losses:         result.losses[:attacker].transform_keys(&:to_s),
        defender_losses:         result.losses[:defender].transform_keys(&:to_s),
        rounds_count:            result.rounds_log.count { |e| !e[:event] },
        metal_pillaged:          metal_pillaged,
        food_pillaged:           food_pillaged,
        thorium_pillaged:        thorium_pillaged,
        attacker_xp_gained:      attacker_xp,
        defender_xp_gained:      defender_xp
      )
    end
  end

  private

  def read_combat_techs(planet)
    planet.planet_technologies
          .where(tech_key: %w[armement blindage_tactique guerre_electronique])
          .pluck(:tech_key, :level)
          .to_h
          .transform_keys(&:to_sym)
          .tap { |h| h[:armement] ||= 0; h[:blindage_tactique] ||= 0; h[:guerre_electronique] ||= 0 }
  end

  def apply_losses(planet, losses)
    losses.each do |type, count|
      unit = planet.units.find_by(unit_type: type.to_s)
      next unless unit

      unit.update!(count: [unit.count - count, 0].max)
    end
  end

  def restitute_survivors(planet, sent_force, losses)
    sent_force.each do |type, sent_count|
      lost      = losses.fetch(type, losses.fetch(type.to_s, 0))
      survivors = [sent_count - lost, 0].max
      next if survivors <= 0

      unit = Unit.find_or_initialize_by(planet: planet, unit_type: type.to_s)
      unit.count = (unit.count || 0) + survivors
      unit.save!
    end
  end
end
