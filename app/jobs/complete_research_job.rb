class CompleteResearchJob < ApplicationJob
  queue_as :default

  def perform(research_queue_id)
    queue = ResearchQueue.find_by(id: research_queue_id)
    return unless queue&.pending?

    queue.reload
    return unless queue.pending?

    ActiveRecord::Base.transaction do
      queue.update!(status: "completed")

      tech = PlanetTechnology.find_or_initialize_by(
        planet: queue.planet, tech_key: queue.tech_key
      )
      tech.level  = queue.target_level
      tech.status = "idle"
      tech.save!
    end
  end
end
