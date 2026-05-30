require "rails_helper"

RSpec.describe Buildings::Calculator do
  describe ".energy_produced" do
    it "returns 0.0 for level 0" do
      expect(described_class.energy_produced(:solar_station, 0)).to eq(0.0)
    end

    it "returns the exact value from the lookup table at level 1" do
      expect(described_class.energy_produced(:solar_station, 1)).to eq(55.0)
    end

    it "returns the exact value at level 2" do
      expect(described_class.energy_produced(:solar_station, 2)).to eq(108.0)
    end

    it "returns 0.0 for a non-energy building" do
      expect(described_class.energy_produced(:metal_mine, 1)).to eq(0.0)
    end

    it "returns 0.0 for command_center" do
      expect(described_class.energy_produced(:command_center, 1)).to eq(0.0)
    end

    it "returns correct value for nuclear_plant" do
      expect(described_class.energy_produced(:nuclear_plant, 1)).to eq(119.0)
    end
  end

  describe ".energy_consumed" do
    it "returns 0.0 for level 0" do
      expect(described_class.energy_consumed(:metal_mine, 0)).to eq(0.0)
    end

    it "returns the exact cumulative value at level 1" do
      expect(described_class.energy_consumed(:metal_mine, 1)).to eq(11.0)
    end

    it "returns the exact cumulative value at level 2" do
      expect(described_class.energy_consumed(:metal_mine, 2)).to eq(46.0)
    end

    it "returns 0.0 for command_center at any level" do
      expect(described_class.energy_consumed(:command_center, 1)).to eq(0.0)
      expect(described_class.energy_consumed(:command_center, 3)).to eq(0.0)
    end

    it "returns 0.0 for solar_station (producer, not consumer)" do
      expect(described_class.energy_consumed(:solar_station, 1)).to eq(0.0)
    end

    it "returns correct value for quantum_portal level 1" do
      expect(described_class.energy_consumed(:quantum_portal, 1)).to eq(33.0)
    end
  end

  describe ".production_rate" do
    it "returns 0.0 for level 0" do
      expect(described_class.production_rate(:metal_mine, 0)).to eq(0.0)
    end

    it "returns 0.0 for energy producers" do
      expect(described_class.production_rate(:solar_station, 1)).to eq(0.0)
    end

    it "returns 0.0 for storage buildings" do
      expect(described_class.production_rate(:metal_warehouse, 1)).to eq(0.0)
    end

    it "returns 0.0 for command_center" do
      expect(described_class.production_rate(:command_center, 1)).to eq(0.0)
    end

    it "returns units/second for metal_mine level 1 (24 units/hour)" do
      expect(described_class.production_rate(:metal_mine, 1)).to be_within(0.000001).of(24.0 / 3600.0)
    end

    it "returns units/second for farm level 1 (18 units/hour)" do
      expect(described_class.production_rate(:farm, 1)).to be_within(0.000001).of(18.0 / 3600.0)
    end

    it "returns units/second for thorium_mine level 1 (18 units/hour)" do
      expect(described_class.production_rate(:thorium_mine, 1)).to be_within(0.000001).of(18.0 / 3600.0)
    end

    it "increases with level" do
      rate1 = described_class.production_rate(:metal_mine, 1)
      rate2 = described_class.production_rate(:metal_mine, 2)
      expect(rate2).to be > rate1
    end
  end

  describe ".storage_capacity" do
    it "returns 1_000 for level 0 on a storage building" do
      expect(described_class.storage_capacity(:metal_warehouse, 0)).to eq(1_000)
    end

    it "returns 1_000 for a non-storage building regardless of level" do
      expect(described_class.storage_capacity(:command_center, 1)).to eq(1_000)
      expect(described_class.storage_capacity(:metal_mine, 5)).to eq(1_000)
    end

    it "returns the exact capacity at level 1" do
      expect(described_class.storage_capacity(:metal_warehouse, 1)).to eq(21_000)
    end

    it "returns the exact capacity at level 2" do
      expect(described_class.storage_capacity(:food_silo, 2)).to eq(28_000)
    end

    it "increases with level" do
      cap1 = described_class.storage_capacity(:metal_warehouse, 1)
      cap2 = described_class.storage_capacity(:metal_warehouse, 2)
      expect(cap2).to be > cap1
    end
  end

  describe ".cost" do
    it "returns the base cost at level 1 for command_center" do
      cost = described_class.cost(:command_center, 1)
      expect(cost[:metal]).to eq(50)
      expect(cost[:food]).to eq(25)
      expect(cost[:thorium]).to eq(0)
    end

    it "returns correct cost for solar_station level 1" do
      cost = described_class.cost(:solar_station, 1)
      expect(cost[:metal]).to eq(50)
      expect(cost[:food]).to eq(25)
    end

    it "returns correct cost for solar_station level 2" do
      cost = described_class.cost(:solar_station, 2)
      expect(cost[:metal]).to eq(75)
      expect(cost[:food]).to eq(37)
    end

    it "increases with level for metal_mine" do
      cost1 = described_class.cost(:metal_mine, 1)[:metal]
      cost2 = described_class.cost(:metal_mine, 2)[:metal]
      expect(cost2).to be > cost1
    end

    it "includes thorium for research_lab" do
      cost = described_class.cost(:research_lab, 1)
      expect(cost[:thorium]).to eq(250)
    end
  end

  describe ".construction_time" do
    it "returns exact time for command_center level 1" do
      expect(described_class.construction_time(:command_center, 1)).to eq(90)
    end

    it "returns exact time for solar_station level 1" do
      expect(described_class.construction_time(:solar_station, 1)).to eq(90)
    end

    it "increases with level" do
      t1 = described_class.construction_time(:metal_mine, 1)
      t2 = described_class.construction_time(:metal_mine, 2)
      expect(t2).to be > t1
    end
  end

  describe ".max_level" do
    it "returns 13 for solar_station" do
      expect(described_class.max_level(:solar_station)).to eq(13)
    end

    it "returns 20 for metal_mine" do
      expect(described_class.max_level(:metal_mine)).to eq(20)
    end
  end

  describe ".level_data" do
    it "raises ArgumentError for an undefined level" do
      max = described_class.max_level(:solar_station)
      expect { described_class.level_data(:solar_station, max + 1) }.to raise_error(ArgumentError, /not defined/)
    end
  end

  describe "Buildings.find!" do
    it "raises ArgumentError for an unknown building type" do
      expect { Buildings.find!(:death_star) }.to raise_error(ArgumentError, /Unknown building type/)
    end

    it "returns the config hash for a known type" do
      expect(Buildings.find!(:command_center)).to be_a(Hash)
    end
  end
end
