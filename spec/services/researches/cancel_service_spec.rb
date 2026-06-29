require "rails_helper"

RSpec.describe Researches::CancelService do
  # Start at 0 so the refund amount is exactly the cost (no capacity interference).
  let(:planet) do
    create(:planet, :player,
      metal_stock: 0, food_stock: 0, thorium_stock: 0,
      resources_updated_at: Time.current)
  end
  let!(:planet_tech) do
    create(:planet_technology, planet: planet, tech_key: "forage_cristallin", level: 0, status: "researching")
  end
  let!(:queue) do
    create(:research_queue,
      planet:       planet,
      tech_key:     "forage_cristallin",
      target_level: 1,
      status:       "pending",
      started_at:   1.hour.ago,
      completes_at: 1.hour.from_now,
      metal_cost:   800,
      food_cost:    480,
      thorium_cost: 320)
  end

  subject(:service) { described_class.new(planet) }

  describe "#call — success" do
    it "returns success" do
      expect(service.call.success?).to be true
    end

    it "refunds metal cost to planet stock" do
      service.call
      expect(planet.reload.metal_stock.to_f).to be_within(1).of(800)
    end

    it "refunds food cost to planet stock" do
      service.call
      expect(planet.reload.food_stock.to_f).to be_within(1).of(480)
    end

    it "refunds thorium cost to planet stock" do
      service.call
      expect(planet.reload.thorium_stock.to_f).to be_within(1).of(320)
    end

    it "marks the research queue as cancelled" do
      service.call
      expect(queue.reload.status).to eq("cancelled")
    end

    it "resets planet_technology status to idle" do
      service.call
      expect(planet_tech.reload.status).to eq("idle")
    end
  end

  describe "#call — no_pending_queue" do
    before { queue.update!(status: "cancelled") }

    it "returns failure when no pending queue exists" do
      result = service.call
      expect(result.success?).to be false
      expect(result.error).to eq("no_pending_queue")
    end
  end
end
