class CompleteConstructionJob < ApplicationJob
  queue_as :default

  def perform(construction_queue_id)
    queue = ConstructionQueue.find_by(id: construction_queue_id)
    return unless queue&.pending?

    queue.planet.with_lock do
      queue.reload
      return unless queue.pending?

      planet = queue.planet
      planet.buildings.load
      planet.calculate_resources!(now: Time.current)

      queue.building.update!(level: queue.target_level)
      queue.update!(status: "completed")
    end
  end
end
