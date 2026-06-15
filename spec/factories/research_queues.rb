FactoryBot.define do
  factory :research_queue do
    association :planet
    tech_key     { "forage_cristallin" }
    target_level { 1 }
    status       { "pending" }
    started_at   { Time.current }
    finishes_at  { 1.hour.from_now }
    metal_cost   { 800 }
    food_cost    { 480 }
    thorium_cost { 320 }
  end
end
