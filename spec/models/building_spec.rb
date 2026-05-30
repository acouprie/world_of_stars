require "rails_helper"

RSpec.describe Building, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:planet) }
  end

  describe "validations" do
    subject { build(:building) }

    it { is_expected.to validate_inclusion_of(:building_type).in_array(Building::VALID_TYPES) }
    it { is_expected.to validate_numericality_of(:level).is_greater_than_or_equal_to(0).only_integer }
    it { is_expected.to validate_uniqueness_of(:planet_id).scoped_to(:building_type) }

    it "is invalid with an unknown building_type" do
      building = build(:building, building_type: "death_ray")
      expect(building).not_to be_valid
      expect(building.errors[:building_type]).to be_present
    end

    it "is invalid with a negative level" do
      building = build(:building, level: -1)
      expect(building).not_to be_valid
    end

    it "is valid with level 0" do
      building = build(:building, level: 0)
      expect(building).to be_valid
    end
  end

  describe "#config" do
    it "returns the building configuration hash" do
      building = build(:building, building_type: "command_center")
      expect(building.config).to eq(Buildings::REGISTRY[:command_center])
    end
  end
end
