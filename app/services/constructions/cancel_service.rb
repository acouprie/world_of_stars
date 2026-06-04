module Constructions
  class CancelService
    Result = Struct.new(:success?, :error, keyword_init: true)

    def initialize(planet)
      @planet = planet
    end

    def call
      planet.with_lock do
        queue = planet.construction_queue
        return failure("no_pending_queue") unless queue&.pending?

        queue.reload
        return failure("no_pending_queue") unless queue.pending?

        building    = queue.building
        cost        = Buildings::Calculator.cost(building.building_type, queue.target_level)
        new_building = building.level == 0

        planet.buildings.load
        planet.calculate_resources!(now: Time.current)

        planet.metal_stock   = planet.metal_stock.to_f   + cost[:metal].to_f
        planet.food_stock    = planet.food_stock.to_f    + cost[:food].to_f
        planet.thorium_stock = planet.thorium_stock.to_f + cost[:thorium].to_f
        planet.save!

        if new_building
          # Destroy queue before building to satisfy the FK constraint (building_id NOT NULL).
          # The queue has no meaningful history for a construction that never completed.
          queue.destroy!
          building.destroy!
        else
          queue.update!(status: "cancelled")
        end

        Result.new(success?: true)
      end
    rescue => e
      failure(e.message)
    end

    private

    attr_reader :planet

    def failure(error)
      Result.new(success?: false, error: error)
    end
  end
end
