FactoryBot.define do
  factory :unit do
    association :planet
    unit_type { "maraudeur" }
    count     { 0 }
  end
end
