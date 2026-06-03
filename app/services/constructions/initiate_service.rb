module Constructions
  class InitiateService
    Result = Struct.new(:success?, :error, :queue, keyword_init: true)

    def initialize(planet, building_type, slot_index: nil)
      @planet        = planet
      @building_type = building_type.to_s
      @slot_index    = slot_index
    end

    def call
      Buildings.find!(@building_type)

      planet.with_lock do
        planet.buildings.load
        planet.calculate_resources!

        return failure("already_building")     if planet.construction_queue&.pending?
        return failure("prerequisite_missing") unless prerequisite_met?

        building = planet.buildings.find_or_initialize_by(building_type: @building_type)
        if building.new_record?
          occupied = planet.buildings.pluck(:slot_index).compact
          chosen = @slot_index if @slot_index && !occupied.include?(@slot_index)
          building.slot_index = chosen || (0..11).find { |i| !occupied.include?(i) } || 0
          building.save!
        end

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
        cq = ConstructionQueue.find_or_initialize_by(planet_id: planet.id)
        cq.assign_attributes(
          building:     building,
          target_level: target,
          status:       "pending",
          started_at:   now,
          completes_at: now + duration.seconds
        )
        cq.save!
        queue = cq

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
      built_levels = planet.buildings.each_with_object({}) do |b, h|
        h[b.building_type.to_sym] = b.level
      end
      config = Buildings::REGISTRY[@building_type.to_sym]
      return false unless (config[:requires] || {}).all? { |req_type, req_level|
        built_levels.fetch(req_type, 0) >= req_level
      }
      building = planet.buildings.find_by(building_type: @building_type)
      target_level = (building&.level || 0) + 1
      Buildings.prerequisites_for(@building_type, target_level).all? { |req_type, req_level|
        built_levels.fetch(req_type, 0) >= req_level
      }
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
