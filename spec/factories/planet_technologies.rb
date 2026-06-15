FactoryBot.define do
  factory :planet_technology do
    association :planet
    tech_key { "forage_cristallin" }
    level    { 0 }
    status   { "idle" }
  end
end
