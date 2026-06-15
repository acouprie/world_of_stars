module Researches
  class QueueController < ApplicationController
    before_action :set_planet

    def create
      result = Researches::StartService.new(
        planet:   @planet,
        user:     Current.user,
        tech_key: params[:tech_key]
      ).call

      if result.success?
        @planet = reload_planet
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace("resources_bar",    partial: "planets/resources_bar",   locals: { planet: @planet }),
              turbo_stream.replace("research-queue-bar", partial: "research/queue_bar",    locals: { planet: @planet }),
              turbo_stream.prepend("flash-messages",   partial: "layouts/flash_notice",    locals: { message: t("flash.researches.started") })
            ]
          end
          format.html { redirect_to planet_research_path(@planet), notice: t("flash.researches.started") }
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.prepend(
              "flash-messages",
              partial: "layouts/flash_alert",
              locals: { message: t("flash.researches.#{result.error}", default: result.error) }
            )
          end
          format.html { redirect_to planet_research_path(@planet), alert: t("flash.researches.#{result.error}", default: result.error) }
        end
      end
    end

    def destroy
      result = Researches::CancelService.new(@planet).call

      if result.success?
        @planet = reload_planet
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace("resources_bar",      partial: "planets/resources_bar", locals: { planet: @planet }),
              turbo_stream.replace("research-queue-bar", partial: "research/queue_bar",    locals: { planet: @planet }),
              turbo_stream.prepend("flash-messages",     partial: "layouts/flash_notice",  locals: { message: t("flash.research_queues.cancelled") })
            ]
          end
          format.html { redirect_to planet_research_path(@planet), notice: t("flash.research_queues.cancelled") }
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.prepend(
              "flash-messages",
              partial: "layouts/flash_alert",
              locals: { message: t("flash.research_queues.#{result.error}", default: result.error) }
            )
          end
          format.html { redirect_to planet_research_path(@planet), alert: t("flash.research_queues.#{result.error}", default: result.error) }
        end
      end
    end

    private

    def set_planet
      @planet = Current.user.planets
                            .includes(:buildings, :planet_technologies, :research_queues)
                            .find(params[:planet_id])
    end

    def reload_planet
      Current.user.planets
                  .includes(:buildings, :planet_technologies, :research_queues)
                  .find(@planet.id)
    end
  end
end
