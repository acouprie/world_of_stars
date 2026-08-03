module Combats
  class StartService
    Result = Struct.new(:success?, :error, :mission, keyword_init: true)

    def initialize(planet:, target_planet:, force:)
      @planet        = planet
      @target_planet = target_planet
      @force         = force.transform_keys(&:to_sym).transform_values(&:to_i).reject { |_, v| v <= 0 }
    end

    def self.call(...)
      new(...).call
    end

    def call
      return failure(:no_quantum_portal_source) unless quantum_portal_built?(@planet)
      return failure(:no_quantum_portal_target) unless quantum_portal_built?(@target_planet)
      return failure(:cannot_attack_own_planet)  if @target_planet.user_id == @planet.user_id
      return failure(:empty_force)               if @force.empty?
      return failure(:invalid_unit_type)          unless valid_unit_types?

      @planet.with_lock do
        @planet.units.load

        return failure(:insufficient_units) unless sufficient_units?

        deduct_units!

        now       = Time.current
        arrives_at = now + 1.hour
        mission   = @planet.combat_missions.create!(
          target_planet:  @target_planet,
          status:         "traveling",
          started_at:     now,
          arrives_at:     arrives_at,
          attacker_force: @force.transform_keys(&:to_s)
        )

        CompleteCombatJob.set(wait_until: arrives_at).perform_later(mission.id)

        Result.new(success?: true, mission: mission)
      end
    rescue ActiveRecord::RecordNotFound
      failure(:insufficient_units)
    end

    private

    def quantum_portal_built?(planet)
      planet.buildings.find_by(building_type: "quantum_portal")&.level.to_i >= 1
    end

    def valid_unit_types?
      @force.keys.all? { |type| Units::REGISTRY.key?(type) }
    end

    def sufficient_units?
      @force.all? do |type, qty|
        unit = @planet.units.detect { |u| u.unit_type == type.to_s }
        unit && unit.count >= qty
      end
    end

    def deduct_units!
      @force.each do |type, qty|
        unit = @planet.units.detect { |u| u.unit_type == type.to_s }
        unit.decrement!(:count, qty)
      end
    end

    def failure(error)
      Result.new(success?: false, error: error)
    end
  end
end
