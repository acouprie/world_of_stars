class BuildingsController < ApplicationController
  before_action :set_planet

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
      redirect_to planet_path(@planet), notice: t("flash.buildings.created")
    else
      redirect_to planet_path(@planet), alert: t("flash.buildings.#{result.error}", default: result.error)
    end
  end

  private

  def set_planet
    @planet = Current.user.planets
                          .includes(:buildings, :construction_queue)
                          .find(params[:planet_id])
  end
end
