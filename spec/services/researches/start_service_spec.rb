require "rails_helper"

RSpec.describe Researches::StartService do
  let(:user) { create(:user, exploration_xp: 1000) } # exploration_level = 1
  # Stocks within default storage capacity (1_000) so calculate_resources! doesn't cap them.
  let(:planet) do
    create(:planet, :player, user: user,
      resources_updated_at: Time.current)
  end

  def add_building(type, level)
    planet.buildings.create!(building_type: type.to_s, level: level, slot_index: planet.buildings.count + 1)
  end

  def service(tech_key = :forage_cristallin)
    described_class.new(planet: planet, user: user, tech_key: tech_key)
  end

  before { add_building(:research_lab, 1) }

  describe "#call — success" do
    it "returns success" do
      expect(service.call.success?).to be true
    end

    it "creates a pending ResearchQueue" do
      service.call
      expect(planet.research_queues.pending.count).to eq(1)
    end

    it "deducts metal cost from planet stock" do
      cost = Technologies.cost_for(:forage_cristallin, 1)
      before_metal = planet.metal_stock.to_f
      service.call
      expect(planet.reload.metal_stock.to_f).to be_within(1).of(before_metal - cost[:metal])
    end

    it "deducts food cost from planet stock" do
      cost = Technologies.cost_for(:forage_cristallin, 1)
      before_food = planet.food_stock.to_f
      service.call
      expect(planet.reload.food_stock.to_f).to be_within(1).of(before_food - cost[:food])
    end

    it "deducts thorium cost from planet stock" do
      cost = Technologies.cost_for(:forage_cristallin, 1)
      before_thorium = planet.thorium_stock.to_f
      service.call
      expect(planet.reload.thorium_stock.to_f).to be_within(1).of(before_thorium - cost[:thorium])
    end

    it "schedules a CompleteResearchJob" do
      expect { service.call }.to have_enqueued_job(CompleteResearchJob)
    end

    it "sets planet_technology status to researching" do
      service.call
      pt = planet.planet_technologies.find_by(tech_key: "forage_cristallin")
      expect(pt.status).to eq("researching")
    end

    it "sets finishes_at in the future" do
      service.call
      expect(planet.research_queues.pending.first.finishes_at).to be > Time.current
    end

    it "stores costs on the queue" do
      cost = Technologies.cost_for(:forage_cristallin, 1)
      service.call
      queue = planet.research_queues.pending.first
      expect(queue.metal_cost).to eq(cost[:metal])
      expect(queue.food_cost).to eq(cost[:food])
      expect(queue.thorium_cost).to eq(cost[:thorium])
    end
  end

  describe "#call — already_researching" do
    before { service.call }

    it "returns failure when a research is already pending" do
      result = service.call
      expect(result.success?).to be false
      expect(result.error).to eq("already_researching")
    end
  end

  describe "#call — insufficient_resources" do
    before { planet.update!(metal_stock: 0, food_stock: 0, thorium_stock: 0) }

    it "returns failure" do
      result = service.call
      expect(result.success?).to be false
      expect(result.error).to eq("insufficient_resources")
    end

    it "does not create a research queue" do
      service.call
      expect(planet.research_queues.count).to eq(0)
    end
  end

  describe "#call — prerequisite_missing" do
    it "returns failure when research_lab is below required level" do
      planet.buildings.find_by(building_type: "research_lab").update!(level: 0)
      result = service.call
      expect(result.success?).to be false
      expect(result.error).to eq("prerequisite_missing")
    end

    it "returns failure when exploration level is insufficient" do
      low_user = create(:user, exploration_xp: 0)
      result = described_class.new(planet: planet, user: low_user, tech_key: :forage_cristallin).call
      expect(result.success?).to be false
      expect(result.error).to eq("prerequisite_missing")
    end

    it "returns failure when cross-tech dependency is not satisfied" do
      planet.buildings.find_by(building_type: "research_lab").update!(level: 2)
      user.update!(exploration_xp: 1440)
      result = service(:raffinage_thorium).call
      expect(result.success?).to be false
      expect(result.error).to eq("prerequisite_missing")
    end
  end

  describe "#call — max_level_reached" do
    before do
      planet.planet_technologies.create!(
        tech_key: "technologie_cristal", level: 1, status: "idle"
      )
    end

    it "returns failure when technology is already at max level" do
      result = service(:technologie_cristal).call
      expect(result.success?).to be false
      expect(result.error).to eq("max_level_reached")
    end
  end

  describe "#call — unknown tech key" do
    it "returns failure with an error message" do
      result = described_class.new(planet: planet, user: user, tech_key: :laser_cannon).call
      expect(result.success?).to be false
    end
  end
end
