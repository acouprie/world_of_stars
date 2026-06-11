require "rails_helper"

RSpec.describe Unit, type: :model do
  let(:planet) { create(:planet) }

  describe "validations" do
    it "is valid with a known unit_type and count >= 0" do
      expect(build(:unit, planet: planet, unit_type: "maraudeur", count: 0)).to be_valid
    end

    it "is invalid for an unknown unit_type" do
      expect(build(:unit, planet: planet, unit_type: "laser_cannon")).not_to be_valid
    end

    it "is invalid with a negative count" do
      expect(build(:unit, planet: planet, count: -1)).not_to be_valid
    end

    it "enforces uniqueness of unit_type per planet" do
      create(:unit, planet: planet, unit_type: "maraudeur")
      expect(build(:unit, planet: planet, unit_type: "maraudeur")).not_to be_valid
    end

    it "allows the same unit_type on different planets" do
      create(:unit, planet: planet, unit_type: "maraudeur")
      other_planet = create(:planet)
      expect(build(:unit, planet: other_planet, unit_type: "maraudeur")).to be_valid
    end
  end
end
