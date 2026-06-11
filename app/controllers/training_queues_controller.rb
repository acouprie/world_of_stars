class TrainingQueuesController < ApplicationController
  before_action :set_planet

  def index
    built = @planet.buildings.each_with_object({}) { |b, h| h[b.building_type.to_sym] = b.level }

    @units_data = Units::REGISTRY.map do |type, config|
      type_s    = type.to_s
      unlocked  = Units.unlocked?(type, @planet)
      cost      = config[:cost]

      can_metal   = @planet.metal_stock.to_f   >= cost[:metal].to_f
      can_food    = @planet.food_stock.to_f    >= cost[:food].to_f
      can_thorium = @planet.thorium_stock.to_f >= cost[:thorium].to_f

      {
        type:       type_s,
        config:     config,
        unlocked:   unlocked,
        combat:     config[:combat],
        cost:       cost,
        can_metal:  can_metal,
        can_food:   can_food,
        can_thorium: can_thorium,
        can_afford: unlocked && can_metal && can_food && can_thorium,
        missing_requires: unlock_reasons(config, built)
      }
    end
  end

  def create
    unit_type = params[:unit_type].to_s
    quantity  = params[:quantity].to_i

    result = Trainings::InitiateService.new(@planet, unit_type, quantity).call

    if result.success?
      @planet = reload_planet
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("resources_bar",       partial: "planets/resources_bar",     locals: { planet: @planet }),
            turbo_stream.replace("training-queues-bar", partial: "training_queues/queues_bar", locals: { planet: @planet }),
            turbo_stream.prepend("flash-messages",      partial: "layouts/flash_notice",       locals: { message: t("flash.trainings.created") }),
          ]
        end
        format.html { redirect_to planet_training_queues_path(@planet), notice: t("flash.trainings.created") }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend(
            "flash-messages",
            partial: "layouts/flash_alert",
            locals: { message: t("flash.trainings.#{result.error}", default: result.error) }
          )
        end
        format.html { redirect_to planet_training_queues_path(@planet), alert: t("flash.trainings.#{result.error}", default: result.error) }
      end
    end
  end

  private

  def set_planet
    @planet = Current.user.planets
                          .includes(:buildings, :training_queues, :units, :user)
                          .find(params[:planet_id])
  end

  def reload_planet
    Current.user.planets
               .includes(:buildings, :training_queues, :units, :user)
               .find(@planet.id)
  end

  def unlock_reasons(config, built)
    all_requires = Units::UNIVERSAL_REQUIRES.merge(config[:requires] || {})
    all_requires.filter_map do |req_type, req_value|
      case req_type
      when :technology
        next if (@planet.user&.technology_level(req_value) || 0) >= 1
        { type: :technology, key: req_value }
      else
        next if built.fetch(req_type, 0) >= req_value
        { type: :building, key: req_type, level: req_value }
      end
    end
  end
end
