require "rails_helper"

RSpec.describe ExplorationMission, type: :model do
  let(:planet)        { create(:planet, :player) }
  let(:target_planet) { create(:planet) }

  def build_mission(**attrs)
    build(:exploration_mission, planet: planet, target_planet: target_planet, **attrs)
  end

  def create_mission(**attrs)
    create(:exploration_mission, planet: planet, target_planet: target_planet, **attrs)
  end

  describe "status validation" do
    it "accepts pending" do
      expect(build_mission(status: "pending")).to be_valid
    end

    it "accepts completed" do
      expect(build_mission(status: "completed")).to be_valid
    end

    it "rejects unknown status" do
      expect(build_mission(status: "cancelled")).not_to be_valid
    end
  end

  describe "max simultaneous missions" do
    it "allows up to 5 pending missions" do
      4.times { create_mission }
      expect(build_mission).to be_valid
    end

    it "rejects a 6th pending mission" do
      5.times { create_mission }
      mission = build_mission
      expect(mission).not_to be_valid
      expect(mission.errors[:base]).not_to be_empty
    end

    it "does not count completed missions toward the limit" do
      5.times { create(:exploration_mission, :completed, planet: planet, target_planet: target_planet) }
      expect(build_mission).to be_valid
    end
  end

  describe "scopes" do
    it "pending scope returns only pending missions" do
      pending_m   = create_mission
      create(:exploration_mission, :completed, planet: planet, target_planet: target_planet)
      expect(ExplorationMission.pending).to eq([pending_m])
    end

    it "completed scope returns only completed missions" do
      create_mission
      completed_m = create(:exploration_mission, :completed, planet: planet, target_planet: target_planet)
      expect(ExplorationMission.completed).to eq([completed_m])
    end
  end
end
