FactoryBot.define do
  factory :training_queue do
    association :planet, factory: [:planet, :player]
    unit_type    { "maraudeur" }
    quantity     { 1 }
    status       { "pending" }
    started_at   { Time.current }
    completes_at { 90.seconds.from_now }
  end
end
