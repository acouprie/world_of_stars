class BuildingsController < ApplicationController
  before_action :set_planet

  def show
    @building = @planet.buildings.find(params[:id])
    type      = @building.building_type
    max       = Buildings::Calculator.max_level(type)

    if @building.level < max
      target       = @building.level + 1
      cost         = Buildings::Calculator.cost(type, target)
      curr_energy  = Buildings::Calculator.energy_consumed(type, @building.level)
      next_energy  = Buildings::Calculator.energy_consumed(type, target)
      energy_delta = next_energy - curr_energy
      duration     = Buildings::Calculator.construction_time(type, target)

      can_metal   = @planet.metal_stock.to_f   >= cost[:metal].to_f
      can_food    = @planet.food_stock.to_f    >= cost[:food].to_f
      can_thorium = @planet.thorium_stock.to_f >= cost[:thorium].to_f
      can_energy  = @planet.net_energy         >= energy_delta

      @upgrade = {
        target_level: target,
        cost:         cost,
        energy_delta: energy_delta,
        duration:     duration,
        can_afford:   can_metal && can_food && can_thorium && can_energy,
        can_metal:    can_metal,
        can_food:     can_food,
        can_thorium:  can_thorium,
        can_energy:   can_energy,
      }
    end

    render layout: false
  end

  def new
    @slot_index = params[:slot_index].to_i

    @buildings_data = @planet.available_building_types.map do |type|
      type_s       = type.to_s
      cost         = Buildings::Calculator.cost(type_s, 1)
      energy_delta = Buildings::Calculator.energy_consumed(type_s, 1)
      duration     = Buildings::Calculator.construction_time(type_s, 1)

      can_metal   = @planet.metal_stock.to_f   >= cost[:metal].to_f
      can_food    = @planet.food_stock.to_f    >= cost[:food].to_f
      can_thorium = @planet.thorium_stock.to_f >= cost[:thorium].to_f
      can_energy  = @planet.net_energy         >= energy_delta

      {
        type:           type_s,
        cost:           cost,
        energy_delta:   energy_delta,
        duration:       duration,
        can_afford:     can_metal && can_food && can_thorium && can_energy,
        can_metal:      can_metal,
        can_food:       can_food,
        can_thorium:    can_thorium,
        can_energy:     can_energy,
      }
    end

    render layout: false
  end

  def create
    building_type = params[:building_type].to_s
    slot_index    = params[:slot_index]&.to_i

    result = Constructions::InitiateService.new(@planet, building_type, slot_index: slot_index).call

    if result.success?
      @planet = Current.user.planets
                            .includes(:buildings, construction_queue: :building)
                            .find(@planet.id)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("resources_bar",  partial: "planets/resources_bar",        locals: { planet: @planet }),
            turbo_stream.replace("planet-canvas",  partial: "planets/canvas_container",     locals: { planet: @planet }),
            turbo_stream.replace("queue-bar",      partial: "construction_queues/queue_bar", locals: { planet: @planet }),
            turbo_stream.prepend("flash-messages", partial: "layouts/flash_notice",          locals: { message: t("flash.buildings.created") }),
          ]
        end
        format.html { redirect_to planet_path(@planet), notice: t("flash.buildings.created") }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend(
            "flash-messages",
            partial: "layouts/flash_alert",
            locals: { message: t("flash.buildings.#{result.error}", default: result.error) }
          )
        end
        format.html { redirect_to planet_path(@planet), alert: t("flash.buildings.#{result.error}", default: result.error) }
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
