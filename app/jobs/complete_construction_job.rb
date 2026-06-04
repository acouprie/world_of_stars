class CompleteConstructionJob < ApplicationJob
  queue_as :default

  def perform(construction_queue_id)
    queue = ConstructionQueue.find_by(id: construction_queue_id)
    return unless queue&.pending?

    planet_id = queue.planet_id

    queue.planet.with_lock do
      queue.reload
      return unless queue.pending?

      planet = queue.planet
      planet.buildings.load
      planet.calculate_resources!(now: Time.current)

      queue.building.update!(level: queue.target_level)
      queue.update!(status: "completed")
    end

    planet = Planet.includes(:buildings, construction_queue: :building).find(planet_id)
    broadcast_completion(planet)
  end

  private

  def broadcast_completion(planet)
    Turbo::StreamsChannel.broadcast_replace_to(
      "planet_#{planet.id}",
      target: "resources_bar",
      partial: "planets/resources_bar",
      locals: { planet: planet }
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      "planet_#{planet.id}",
      target: "planet-canvas",
      partial: "planets/canvas_container",
      locals: { planet: planet }
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      "planet_#{planet.id}",
      target: "queue-bar",
      partial: "construction_queues/queue_bar",
      locals: { planet: planet }
    )

    Turbo::StreamsChannel.broadcast_update_to(
      "planet_#{planet.id}",
      target: "buildings-list-container",
      partial: "planets/buildings_list",
      locals: { planet: planet }
    )

    Turbo::StreamsChannel.broadcast_prepend_to(
      "planet_#{planet.id}",
      target: "flash-messages",
      partial: "layouts/flash_notice",
      locals: { message: I18n.t("flash.buildings.completed") }
    )
  end
end
