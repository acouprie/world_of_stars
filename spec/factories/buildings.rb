FactoryBot.define do
  factory :building do
    association :planet
    building_type { "command_center" }
    level         { 1 }
    slot_index    { 1 }
  end
end
