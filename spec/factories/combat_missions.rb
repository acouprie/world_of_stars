FactoryBot.define do
  factory :combat_mission do
    association :planet
    association :target_planet, factory: :planet
    status         { "traveling" }
    started_at     { Time.current }
    arrives_at     { 1.hour.from_now }
    attacker_force { { "maraudeur" => 5 } }

    trait :completed do
      status                   { "completed" }
      arrives_at                { 1.hour.ago }
      outcome                   { "attacker_wins" }
      defender_force_snapshot   { {} }
      attacker_losses           { {} }
      defender_losses           { {} }
      rounds_count               { 3 }
    end
  end
end
