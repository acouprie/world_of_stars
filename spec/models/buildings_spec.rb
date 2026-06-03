require "rails_helper"

RSpec.describe Buildings do
  describe "REGISTRY" do
    it "defines all 16 building types" do
      expect(Buildings::REGISTRY.keys.size).to eq(16)
    end

    it "has a description for every building" do
      Buildings::REGISTRY.each do |type, config|
        expect(config[:description]).to be_present, "Missing description for #{type}"
      end
    end

    it "has a non-blank description for every building" do
      Buildings::REGISTRY.each do |type, config|
        expect(config[:description]).not_to be_empty, "Empty description for #{type}"
      end
    end
  end


  describe ".prerequisites_for" do
    it "returns the prerequisites for level 1" do
      expect(Buildings.prerequisites_for(:solar_station, 1)).to eq({ command_center: 1 })
    end

    it "returns level-1 prerequisites when between two thresholds" do
      expect(Buildings.prerequisites_for(:solar_station, 3)).to eq({ command_center: 1 })
    end

    it "returns upgraded prerequisites when a higher threshold is reached" do
      expect(Buildings.prerequisites_for(:solar_station, 4)).to eq({ command_center: 3 })
    end

    it "applies the nearest threshold below the target level" do
      expect(Buildings.prerequisites_for(:solar_station, 6)).to eq({ command_center: 3 })
    end

    it "returns {} for command_center (no prerequisites)" do
      expect(Buildings.prerequisites_for(:command_center, 1)).to eq({})
    end

    it "returns {} for an unknown building type" do
      expect(Buildings.prerequisites_for(:laser_cannon, 1)).to eq({})
    end
  end
end
