require "rails_helper"

RSpec.describe Planet, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to have_many(:buildings).dependent(:destroy) }
    it { is_expected.to have_one(:construction_queue).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:planet) }

    it { is_expected.to validate_inclusion_of(:planet_type).in_array(Planet::PLANET_TYPES) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:coord_x) }
    it { is_expected.to validate_presence_of(:coord_y) }

    it "is invalid with an unknown planet_type" do
      planet = build(:planet, planet_type: "moon")
      expect(planet).not_to be_valid
    end

    it "is invalid with negative metal_stock" do
      planet = build(:planet, metal_stock: -1)
      expect(planet).not_to be_valid
    end
  end

  describe "energy calculations" do
    let(:planet) { create(:planet, :player) }

    context "with no buildings" do
      it "has zero energy produced" do
        planet.buildings.load
        expect(planet.total_energy_produced).to eq(0.0)
      end

      it "has zero energy consumed" do
        planet.buildings.load
        expect(planet.total_energy_consumed).to eq(0.0)
      end

      it "has zero net energy" do
        planet.buildings.load
        expect(planet.net_energy).to eq(0.0)
      end
    end

    context "with a solar station at level 2" do
      before { create(:building, planet: planet, building_type: "solar_station", level: 2) }

      it "has positive energy produced" do
        planet.buildings.reload
        expect(planet.total_energy_produced).to be > 0
      end

      it "consumes no energy (solar_station energy_cost = 0)" do
        planet.buildings.reload
        expect(planet.total_energy_consumed).to eq(0.0)
      end

      it "has positive net energy" do
        planet.buildings.reload
        expect(planet.net_energy).to be > 0
      end
    end

    context "with energy production and consumption" do
      before do
        create(:building, planet: planet, building_type: "solar_station", level: 1)
        create(:building, planet: planet, building_type: "metal_mine",    level: 1)
      end

      it "net energy = produced - consumed" do
        planet.buildings.reload
        expected = planet.total_energy_produced - planet.total_energy_consumed
        expect(planet.net_energy).to eq(expected)
      end
    end
  end

  describe "#calculate_resources!" do
    let(:anchor) { Time.current - 1.hour }
    let(:planet) { create(:planet, :player, metal_stock: 0.0, food_stock: 0.0, thorium_stock: 0.0, resources_updated_at: anchor) }

    context "with a metal mine at level 1" do
      before do
        create(:building, planet: planet, building_type: "metal_mine", level: 1)
        planet.buildings.load
      end

      it "accumulates metal based on elapsed time" do
        rate     = Buildings::Calculator.production_rate(:metal_mine, 1)
        expected = rate * 3600

        planet.calculate_resources!(now: anchor + 1.hour)

        expect(planet.metal_stock.to_f).to be_within(0.001).of(expected)
      end

      it "updates resources_updated_at to the given time" do
        now = anchor + 1.hour
        planet.calculate_resources!(now: now)
        expect(planet.resources_updated_at).to be_within(1.second).of(now)
      end

      it "persists changes to the database" do
        planet.calculate_resources!(now: anchor + 1.hour)
        expect(planet.reload.metal_stock.to_f).to be > 0
      end
    end

    context "caps at storage capacity" do
      before do
        planet.update!(metal_stock: planet.metal_capacity - 0.001)
        create(:building, planet: planet, building_type: "metal_mine", level: 5)
        planet.buildings.load
      end

      it "does not exceed metal_capacity" do
        planet.calculate_resources!(now: anchor + 1.day)
        expect(planet.metal_stock.to_f).to be <= planet.metal_capacity.to_f
      end
    end

    context "with no production buildings" do
      before { planet.buildings.load }

      it "stocks remain at zero" do
        planet.calculate_resources!(now: anchor + 2.hours)
        expect(planet.metal_stock.to_f).to eq(0.0)
        expect(planet.food_stock.to_f).to eq(0.0)
        expect(planet.thorium_stock.to_f).to eq(0.0)
      end
    end

    context "with negative elapsed time (clock edge case)" do
      before { planet.buildings.load }

      it "does not subtract from stocks" do
        planet.calculate_resources!(now: anchor - 10.seconds)
        expect(planet.metal_stock.to_f).to eq(0.0)
      end
    end
  end

  describe "storage capacities" do
    let(:planet) { create(:planet, :player) }

    it "returns 1_000 metal_capacity with no warehouse" do
      planet.buildings.load
      expect(planet.metal_capacity).to eq(1_000)
    end

    it "returns higher metal_capacity when metal_warehouse is built" do
      create(:building, planet: planet, building_type: "metal_warehouse", level: 1)
      planet.buildings.reload
      expect(planet.metal_capacity).to be > 1_000
    end
  end

  describe "#available_building_types" do
    let(:planet) { create(:planet, :player) }

    it "returns only command_center when no buildings exist" do
      planet.buildings.load
      expect(planet.available_building_types).to eq([ :command_center ])
    end

    it "excludes command_center once it is built" do
      create(:building, planet: planet, building_type: "command_center", level: 1)
      planet.buildings.reload
      expect(planet.available_building_types).not_to include(:command_center)
    end

    it "unlocks buildings that require command_center level 1 once it is built" do
      create(:building, planet: planet, building_type: "command_center", level: 1)
      planet.buildings.reload
      expect(planet.available_building_types).to include(:solar_station, :metal_mine, :farm)
    end

    it "does not include a building whose prerequisite is not yet met" do
      planet.buildings.load
      expect(planet.available_building_types).not_to include(:solar_station)
    end

    it "does not include nuclear_plant when CC is only level 1 (requires CC level 5)" do
      create(:building, planet: planet, building_type: "command_center", level: 1)
      planet.buildings.reload
      expect(planet.available_building_types).not_to include(:nuclear_plant)
    end

    it "unlocks nuclear_plant once CC reaches level 5" do
      create(:building, planet: planet, building_type: "command_center", level: 5)
      planet.buildings.reload
      expect(planet.available_building_types).to include(:nuclear_plant)
    end
  end

  describe "production rates" do
    let(:planet) { create(:planet, :player) }

    it "returns 0 metal rate with no mine" do
      planet.buildings.load
      expect(planet.metal_rate).to eq(0.0)
    end

    it "returns positive metal rate when mine is built" do
      create(:building, planet: planet, building_type: "metal_mine", level: 2)
      planet.buildings.reload
      expect(planet.metal_rate).to be > 0
    end
  end
end
