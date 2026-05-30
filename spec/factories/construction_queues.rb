FactoryBot.define do
  factory :construction_queue do
    association :planet
    association :building
    target_level { 2 }
    status       { "pending" }
    started_at   { Time.current }
    completes_at { 1.hour.from_now }
  end
end
