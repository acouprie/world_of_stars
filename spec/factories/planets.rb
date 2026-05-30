FactoryBot.define do
  factory :planet do
    sequence(:coord_x) { |n| n % 50 }
    sequence(:coord_y) { |n| n / 50 }
    sequence(:name)    { |n| "Planet #{n}" }
    planet_type          { "empty" }
    is_home              { false }
    metal_stock          { 1_000 }
    food_stock           { 1_000 }
    thorium_stock        { 500 }
    resources_updated_at { Time.current }

    trait :player do
      association :user
      planet_type { "player" }
    end

    trait :home do
      association :user
      planet_type { "player" }
      is_home     { true }
    end

    trait :ai_faction do
      planet_type { "ai_faction" }
    end
  end
end
