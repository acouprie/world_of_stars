require "rails_helper"

RSpec.describe Technologies do
  let(:user)   { build(:user, exploration_xp: 1000) } # exploration_level = 1
  let(:planet) do
    create(:planet, :player, user: user,
      metal_stock: 100_000, food_stock: 100_000, thorium_stock: 100_000,
      resources_updated_at: Time.current)
  end

  def add_building(planet, type, level)
    planet.buildings.create!(building_type: type.to_s, level: level, slot_index: planet.buildings.count + 1)
  end

  def add_tech(planet, key, level)
    planet.planet_technologies.create!(tech_key: key.to_s, level: level, status: "idle")
  end

  describe ".prerequisites_met?" do
    context "forage_cristallin level 1 (requires research_lab:1, exploration:1)" do
      before { add_building(planet, :research_lab, 1) }

      it "returns true when all prerequisites are satisfied" do
        expect(described_class.prerequisites_met?(:forage_cristallin, 1, planet, user)).to be true
      end

      it "returns false when research_lab is below required level" do
        planet.buildings.find_by(building_type: "research_lab").update!(level: 0)
        expect(described_class.prerequisites_met?(:forage_cristallin, 1, planet, user)).to be false
      end

      it "returns false when exploration level is insufficient" do
        low_user = build(:user, exploration_xp: 0) # exploration_level = 0
        expect(described_class.prerequisites_met?(:forage_cristallin, 1, planet, low_user)).to be false
      end
    end

    context "raffinage_thorium level 1 (requires forage_cristallin:5)" do
      before do
        add_building(planet, :research_lab, 2)
        user.exploration_xp = 1440 # exploration_level = 3 (>= 2 required)
      end

      it "returns false when cross-tech dependency (forage_cristallin) is not satisfied" do
        expect(described_class.prerequisites_met?(:raffinage_thorium, 1, planet, user)).to be false
      end

      it "returns true when forage_cristallin is at required level" do
        add_tech(planet, :forage_cristallin, 5)
        planet.planet_technologies.reload
        expect(described_class.prerequisites_met?(:raffinage_thorium, 1, planet, user)).to be true
      end
    end

    context "armement — checkpoint at level 7 (requires military_camp:4)" do
      before do
        add_building(planet, :research_lab, 4)
        add_building(planet, :military_camp, 3) # below required 4
        user.exploration_xp = 1728 # exploration_level = 4
      end

      it "returns false when military_camp checkpoint is not satisfied for target level 7" do
        expect(described_class.prerequisites_met?(:armement, 7, planet, user)).to be false
      end

      it "returns true once military_camp reaches required level" do
        planet.buildings.find_by(building_type: "military_camp").update!(level: 4)
        planet.buildings.reload
        expect(described_class.prerequisites_met?(:armement, 7, planet, user)).to be true
      end
    end

    context "technologie_cristal level 1 (no LEVEL_PREREQUISITES)" do
      before { add_building(planet, :research_lab, 1) }

      it "returns true with lab 1 and exploration 1" do
        expect(described_class.prerequisites_met?(:technologie_cristal, 1, planet, user)).to be true
      end
    end
  end
end
