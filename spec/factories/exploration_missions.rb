FactoryBot.define do
  factory :exploration_mission do
    association :planet
    association :target_planet, factory: :planet
    status          { "pending" }
    started_at      { Time.current }
    finishes_at     { 30.minutes.from_now }
    force_snapshot  { { "sonde" => 2 } }
    exploration_points { 0 }
    metal_gained    { 0 }
    food_gained     { 0 }
    thorium_gained  { 0 }

    trait :completed do
      status             { "completed" }
      finishes_at        { 1.hour.ago }
      exploration_points { 50 }
      losses_snapshot    { {} }
    end
  end
end
