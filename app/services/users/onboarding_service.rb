module Users
  class OnboardingService
    STARTING_RESOURCES = {
      metal_stock:   500,
      food_stock:    500,
      thorium_stock: 100
    }.freeze

    def initialize(user)
      @user = user
    end

    def call
      planet = Planet
        .where(planet_type: "empty", user_id: nil)
        .order("RANDOM()")
        .lock
        .first

      raise "No empty planet available for onboarding" unless planet

      planet.update!(
        user:                 @user,
        planet_type:          "player",
        is_home:              true,
        resources_updated_at: Time.current,
        **STARTING_RESOURCES
      )

      planet
    end
  end
end
