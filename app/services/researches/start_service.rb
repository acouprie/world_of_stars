module Researches
  class StartService
    Result = Struct.new(:success?, :error, :queue, keyword_init: true)

    def initialize(planet:, user:, tech_key:)
      @planet   = planet
      @user     = user
      @tech_key = tech_key.to_sym
    end

    def call
      Technologies.for(@tech_key)

      planet.with_lock do
        planet.buildings.load
        planet.planet_technologies.load
        planet.calculate_resources!

        return failure("already_researching") if planet.research_queues.pending.any?

        planet_tech = planet.planet_technologies.find_or_initialize_by(tech_key: @tech_key.to_s)
        target_level = planet_tech.level + 1

        return failure("max_level_reached")    if target_level > Technologies.max_level(@tech_key)
        return failure("prerequisite_missing") unless Technologies.prerequisites_met?(@tech_key, target_level, planet, @user)

        cost = Technologies.cost_for(@tech_key, target_level)
        return failure("insufficient_resources") unless can_afford?(cost)

        deduct_resources!(cost)

        duration = cost[:time] / GameSpeed::MULTIPLIER
        now      = Time.current

        planet_tech.save! if planet_tech.new_record?

        queue = planet.research_queues.create!(
          tech_key:     @tech_key.to_s,
          target_level: target_level,
          status:       "pending",
          started_at:   now,
          completes_at: now + duration.seconds,
          metal_cost:   cost[:metal],
          food_cost:    cost[:food],
          thorium_cost: cost[:thorium]
        )

        planet_tech.update!(status: "researching")
        planet.save!

        job_id = CompleteResearchJob
                   .set(wait_until: queue.completes_at)
                   .perform_later(queue.id)
                   .job_id
        queue.update_column(:sidekiq_job_id, job_id)

        Result.new(success?: true, queue: queue)
      end
    rescue KeyError => e
      failure(e.message)
    end

    private

    attr_reader :planet, :user

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
