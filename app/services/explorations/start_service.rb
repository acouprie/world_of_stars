module Explorations
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
      return failure(:no_quantum_portal)  unless quantum_portal_built?
      return failure(:target_not_empty)   unless @target_planet.planet_type == "empty"
      return failure(:empty_force)        if @force.empty?
      return failure(:invalid_unit_type)  unless valid_unit_types?

      @planet.with_lock do
        @planet.units.load

        return failure(:insufficient_units)       unless sufficient_units?
        return failure(:max_simultaneous_reached) unless slot_available?

        deduct_units!

        duration = (20 + @force.values.sum).minutes
        now      = Time.current
        mission  = @planet.exploration_missions.create!(
          target_planet:  @target_planet,
          status:         "pending",
          started_at:     now,
          finishes_at:    now + duration,
          force_snapshot: @force.transform_keys(&:to_s)
        )

        CompleteExplorationJob.set(wait_until: mission.finishes_at).perform_later(mission.id)

        Result.new(success?: true, mission: mission)
      end
    rescue ActiveRecord::RecordNotFound
      failure(:insufficient_units)
    end

    private

    def quantum_portal_built?
      @planet.buildings.exists?(building_type: "quantum_portal")
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

    def slot_available?
      @planet.exploration_missions.pending.count < Explorations::MAX_SIMULTANEOUS_EXPLORATIONS
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
