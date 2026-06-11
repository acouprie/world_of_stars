class CompleteTrainingJob < ApplicationJob
  queue_as :default

  def perform(training_queue_id)
    queue = TrainingQueue.find_by(id: training_queue_id)
    return unless queue&.pending?

    planet_id = queue.planet_id

    queue.planet.with_lock do
      queue.reload
      return unless queue.pending?

      planet     = queue.planet
      unit_entry = planet.units.find_or_initialize_by(unit_type: queue.unit_type)
      unit_entry.count = unit_entry.count.to_i + queue.quantity
      unit_entry.save!

      queue.update!(status: "completed")
    end

    planet = Planet.includes(:buildings, :training_queues, :units).find(planet_id)
    broadcast_completion(planet)
  end

  private

  def broadcast_completion(planet)
    Turbo::StreamsChannel.broadcast_replace_to(
      "planet_#{planet.id}",
      target: "training-queues-bar",
      partial: "training_queues/queues_bar",
      locals: { planet: planet }
    )

    Turbo::StreamsChannel.broadcast_prepend_to(
      "planet_#{planet.id}",
      target: "flash-messages",
      partial: "layouts/flash_notice",
      locals: { message: I18n.t("flash.trainings.completed") }
    )
  end
end
