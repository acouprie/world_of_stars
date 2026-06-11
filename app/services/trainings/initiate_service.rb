module Trainings
  class InitiateService
    Result = Struct.new(:success?, :error, :queue, keyword_init: true)

    def initialize(planet, unit_type, quantity)
      @planet    = planet
      @unit_type = unit_type.to_s
      @quantity  = quantity.to_i
    end

    def call
      Units.find!(@unit_type)
      return failure("invalid_quantity") unless @quantity > 0

      planet.with_lock do
        planet.buildings.load
        planet.calculate_resources!

        return failure("queue_full")           unless queue_slot_available?
        return failure("prerequisite_missing") unless prerequisite_met?

        cost = total_cost
        return failure("insufficient_resources") unless can_afford?(cost)

        deduct_resources!(cost)

        camp_level    = building_level(:training_camp)
        time_per_unit = Units.training_time(@unit_type, camp_level)
        duration      = time_per_unit * @quantity

        now   = Time.current
        queue = planet.training_queues.create!(
          unit_type:    @unit_type,
          quantity:     @quantity,
          status:       "pending",
          started_at:   now,
          completes_at: now + duration.seconds
        )

        planet.save!

        job_id = CompleteTrainingJob
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

    def queue_slot_available?
      planet.training_queues.pending.count < planet.training_queue_slots
    end

    def prerequisite_met?
      config       = Units::REGISTRY[@unit_type.to_sym]
      all_requires = Units::UNIVERSAL_REQUIRES.merge(config[:requires] || {})
      all_requires.all? do |req_type, req_value|
        case req_type
        when :technology
          (planet.user&.technology_level(req_value) || 0) >= 1
        else
          building_level(req_type) >= req_value
        end
      end
    end

    def building_level(type)
      planet.buildings.detect { |b| b.building_type == type.to_s }&.level || 0
    end

    def total_cost
      base = Units.cost_for(@unit_type)
      { metal: base[:metal] * @quantity, food: base[:food] * @quantity, thorium: base[:thorium] * @quantity }
    end

    def can_afford?(cost)
      planet.metal_stock.to_f    >= cost[:metal].to_f &&
        planet.food_stock.to_f   >= cost[:food].to_f &&
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
