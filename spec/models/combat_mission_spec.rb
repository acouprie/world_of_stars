require "rails_helper"

RSpec.describe CombatMission, type: :model do
  let(:planet)        { create(:planet, :player) }
  let(:target_planet) { create(:planet, :player) }

  def build_mission(**attrs)
    build(:combat_mission, planet: planet, target_planet: target_planet, **attrs)
  end

  def create_mission(*traits, **attrs)
    create(:combat_mission, *traits, planet: planet, target_planet: target_planet, **attrs)
  end

  describe "associations" do
    it "is valid with valid attributes" do
      expect(build_mission).to be_valid
    end
  end

  describe "status validation" do
    it "accepts traveling" do
      expect(build_mission(status: "traveling")).to be_valid
    end

    it "accepts completed" do
      expect(build_mission(status: "completed")).to be_valid
    end

    it "rejects unknown status" do
      expect(build_mission(status: "cancelled")).not_to be_valid
    end
  end

  describe "scopes" do
    it "traveling scope returns only traveling missions" do
      traveling_m = create_mission
      create_mission(:completed)
      expect(CombatMission.traveling).to eq([traveling_m])
    end

    it "completed scope returns only completed missions" do
      create_mission
      completed_m = create_mission(:completed)
      expect(CombatMission.completed).to eq([completed_m])
    end

    it "involving scope returns missions where the planet is attacker or defender" do
      outgoing = create_mission
      other_planet = create(:planet, :player)
      incoming = create(:combat_mission, planet: other_planet, target_planet: planet)
      create(:combat_mission, planet: other_planet, target_planet: create(:planet, :player))

      expect(CombatMission.involving(planet)).to contain_exactly(outgoing, incoming)
    end
  end
end
