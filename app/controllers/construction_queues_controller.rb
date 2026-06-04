class ConstructionQueuesController < ApplicationController
  before_action :set_planet

  def destroy
    result = Constructions::CancelService.new(@planet).call

    if result.success?
      @planet = Current.user.planets
                            .includes(:buildings, construction_queue: :building)
                            .find(@planet.id)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("resources_bar",  partial: "planets/resources_bar",         locals: { planet: @planet }),
            turbo_stream.replace("planet-canvas",  partial: "planets/canvas_container",      locals: { planet: @planet }),
            turbo_stream.replace("queue-bar",      partial: "construction_queues/queue_bar",  locals: { planet: @planet }),
            turbo_stream.update("buildings-list-container", partial: "planets/buildings_list", locals: { planet: @planet }),
            turbo_stream.prepend("flash-messages", partial: "layouts/flash_notice",           locals: { message: t("flash.construction_queues.cancelled") }),
          ]
        end
        format.html { redirect_to planet_path(@planet), notice: t("flash.construction_queues.cancelled") }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend(
            "flash-messages",
            partial: "layouts/flash_alert",
            locals: { message: t("flash.construction_queues.#{result.error}", default: result.error) }
          )
        end
        format.html { redirect_to planet_path(@planet), alert: t("flash.construction_queues.#{result.error}", default: result.error) }
      end
    end
  end

  private

  def set_planet
    @planet = Current.user.planets
                          .includes(:buildings, construction_queue: :building)
                          .find(params[:planet_id])
  end
end
