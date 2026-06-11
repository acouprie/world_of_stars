require "rails_helper"

RSpec.describe Units do
  describe "REGISTRY" do
    it "defines exactly 7 unit types" do
      expect(Units::REGISTRY.keys.size).to eq(7)
    end

    it "includes all expected types" do
      expect(Units::REGISTRY.keys).to match_array(
        %i[maraudeur regulier sentinelle scientifique sonde spectre mule]
      )
    end

    it "has cost, base_time, requires, stats, and category for every entry" do
      Units::REGISTRY.each do |type, config|
        expect(config[:cost]).to be_present,     "#{type}: missing cost"
        expect(config[:base_time]).to be_present, "#{type}: missing base_time"
        expect(config).to have_key(:requires),    "#{type}: missing requires"
        expect(config[:stats]).to be_present,     "#{type}: missing stats"
        expect(config[:category]).to be_present,  "#{type}: missing category"
      end
    end
  end

  describe "stats v2.1 (source of truth: unit_reference §3)" do
    {
      maraudeur:    { atk: 16, def: 20, int: 6  },
      regulier:     { atk: 11, def: 30, int: 8  },
      sentinelle:   { atk: 13, def: 38, int: 10 },
      scientifique: { atk: 2,  def: 14, int: 7  },
      sonde:        { atk: 0,  def: 12, int: 4  },
      spectre:      { atk: 0,  def: 10, int: 2  },
      mule:         { atk: 0,  def: 16, int: 1  }
    }.each do |type, expected|
      it "#{type} has ATQ #{expected[:atk]}, DEF #{expected[:def]}, INT #{expected[:int]}" do
        stats = Units::REGISTRY[type][:stats]
        expect(stats[:atk]).to eq(expected[:atk])
        expect(stats[:def]).to eq(expected[:def])
        expect(stats[:int]).to eq(expected[:int])
      end
    end
  end

  describe "costs (unit_reference §4, k=1 baseline)" do
    {
      maraudeur:    { metal: 70, food: 30, thorium: 0  },
      regulier:     { metal: 75, food: 30, thorium: 10 },
      sentinelle:   { metal: 95, food: 35, thorium: 30 },
      scientifique: { metal: 60, food: 45, thorium: 25 },
      sonde:        { metal: 80, food: 40, thorium: 30 },
      spectre:      { metal: 70, food: 25, thorium: 40 },
      mule:         { metal: 70, food: 40, thorium: 0  }
    }.each do |type, expected|
      it "#{type} has cost #{expected}" do
        expect(Units.cost_for(type)).to eq(expected)
      end
    end
  end

  describe ".combat?" do
    it "returns true for maraudeur, regulier, sentinelle" do
      expect(Units.combat?(:maraudeur)).to   be true
      expect(Units.combat?(:regulier)).to    be true
      expect(Units.combat?(:sentinelle)).to  be true
    end

    it "returns false for scientifique despite ATQ 2" do
      expect(Units.combat?(:scientifique)).to be false
    end

    it "returns false for sonde, spectre, mule" do
      expect(Units.combat?(:sonde)).to   be false
      expect(Units.combat?(:spectre)).to be false
      expect(Units.combat?(:mule)).to    be false
    end
  end

  describe ".find!" do
    it "returns the config for a known type" do
      expect(Units.find!(:maraudeur)).to eq(Units::REGISTRY[:maraudeur])
    end

    it "raises ArgumentError for an unknown type" do
      expect { Units.find!(:laser_cannon) }.to raise_error(ArgumentError, /Unknown unit type/)
    end
  end

  describe ".training_time" do
    let(:base) { Units::REGISTRY[:maraudeur][:base_time] }

    it "equals base_time at camp level 1" do
      expect(Units.training_time(:maraudeur, 1)).to eq(base)
    end

    it "applies the 0.95 coefficient per level" do
      expected = (base * 0.95).ceil
      expect(Units.training_time(:maraudeur, 2)).to eq(expected)
    end

    it "floors camp level at 1 so time never exceeds base_time" do
      expect(Units.training_time(:maraudeur, 0)).to eq(base)
    end
  end

  describe "stub hooks" do
    it "explore returns an empty hash" do
      expect(Units.explore({})).to eq({})
    end

    it "spy returns an empty hash" do
      expect(Units.spy({})).to eq({})
    end
  end
end
