module Constructions
  class InitiateService
    Result = Struct.new(:success?, :error, :queue, keyword_init: true)

    def initialize(planet, building_type)
      @planet        = planet
      @building_type = building_type.to_s
    end

    def call
      Buildings.find!(@building_type)

      planet.with_lock do
        planet.buildings.load
        planet.calculate_resources!

        return failure("already_building")     if planet.construction_queue&.pending?
        return failure("prerequisite_missing") unless prerequisite_met?

        building = planet.buildings.find_or_initialize_by(building_type: @building_type)
        building.save! if building.new_record?

        target = building.level + 1

        current_energy_cost = Buildings::Calculator.energy_consumed(@building_type, building.level)
        next_energy_cost    = Buildings::Calculator.energy_consumed(@building_type, target)
        additional_energy   = next_energy_cost - current_energy_cost

        return failure("insufficient_energy")    if planet.net_energy < additional_energy

        cost = Buildings::Calculator.cost(@building_type, target)
        return failure("insufficient_resources") unless can_afford?(cost)

        deduct_resources!(cost)

        duration     = Buildings::Calculator.construction_time(@building_type, target)
        now          = Time.current
        queue = planet.create_construction_queue!(
          building:     building,
          target_level: target,
          status:       "pending",
          started_at:   now,
          completes_at: now + duration.seconds
        )

        planet.save!

        job_id = CompleteConstructionJob
                   .set(wait_until: queue.completes_at)
                   .perform_later(queue.id)
                   .job_id
        queue.update_column(:sidekiq_job_id, job_id)

        Result.new(success?: true, queue: queue)
      end
    rescue ArgumentError => e
      failure(e.message)
    end

    private

    attr_reader :planet

    def prerequisite_met?
      return true if @building_type == "command_center"
      planet.buildings.any? { |b| b.building_type == "command_center" && b.level >= 1 }
    end

    def can_afford?(cost)
      planet.metal_stock.to_f   >= cost[:metal].to_f &&
        planet.food_stock.to_f  >= cost[:food].to_f &&
        planet.thorium_stock.to_f >= cost[:thorium].to_f
    end

    def deduct_resources!(cost)
      planet.metal_stock   = planet.metal_stock.to_f   - cost[:metal].to_f
      planet.food_stock    = planet.food_stock.to_f    - cost[:food].to_f
      planet.thorium_stock = planet.thorium_stock.to_f - cost[:thorium].to_f
    end

    def failure(error)
      Result.new(success?: false, error: error)
    end
  end
end
