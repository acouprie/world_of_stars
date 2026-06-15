module Researches
  class CancelService
    Result = Struct.new(:success?, :error, keyword_init: true)

    def initialize(planet)
      @planet = planet
    end

    def call
      planet.with_lock do
        queue = planet.research_queues.pending.first
        return failure("no_pending_queue") unless queue

        queue.reload
        return failure("no_pending_queue") unless queue.pending?

        planet.calculate_resources!(now: Time.current)

        planet.metal_stock   = planet.metal_stock.to_f   + queue.metal_cost.to_f
        planet.food_stock    = planet.food_stock.to_f    + queue.food_cost.to_f
        planet.thorium_stock = planet.thorium_stock.to_f + queue.thorium_cost.to_f
        planet.save!

        queue.update!(status: "cancelled")

        tech = planet.planet_technologies.find_by(tech_key: queue.tech_key)
        tech&.update!(status: "idle")

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
