require "rails_helper"

RSpec.describe Constructions::CancelService do
  let(:user) { create(:user) }
  # Resources already reduced by command_center level-1 cost (metal: 50, food: 25, thorium: 0)
  let(:planet) do
    create(:planet, :player, user: user,
      metal_stock:          750,
      food_stock:           775,
      thorium_stock:        400,
      resources_updated_at: Time.current)
  end

  subject(:service) { described_class.new(planet) }

  describe "#call — new building (level 0, slot freed on cancel)" do
    let(:building) { create(:building, planet: planet, building_type: "command_center", level: 0, slot_index: 0) }
    let!(:queue) do
      create(:construction_queue,
        planet:       planet,
        building:     building,
        target_level: 1,
        status:       "pending",
        started_at:   Time.current,
        completes_at: 1.hour.from_now)
    end

    it "returns success" do
      expect(service.call.success?).to be true
    end

    it "destroys the queue record (no meaningful history for a never-built building)" do
      service.call
      expect { queue.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "destroys the building to free the slot" do
      service.call
      expect { building.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "refunds metal" do
      cost = Buildings::Calculator.cost("command_center", 1)
      service.call
      expect(planet.reload.metal_stock.to_f).to be_within(1).of(750 + cost[:metal])
    end

    it "refunds food" do
      cost = Buildings::Calculator.cost("command_center", 1)
      service.call
      expect(planet.reload.food_stock.to_f).to be_within(1).of(775 + cost[:food])
    end

    it "leaves thorium unchanged when cost is zero" do
      service.call
      expect(planet.reload.thorium_stock.to_f).to be_within(1).of(400)
    end
  end

  describe "#call — upgrade (level > 0, building kept)" do
    let(:building) { create(:building, planet: planet, building_type: "solar_station", level: 1, slot_index: 1) }
    let!(:queue) do
      # solar_station level 2: metal=75, food=37, thorium=0
      create(:construction_queue,
        planet:       planet,
        building:     building,
        target_level: 2,
        status:       "pending",
        started_at:   Time.current,
        completes_at: 1.hour.from_now)
    end

    it "returns success" do
      expect(service.call.success?).to be true
    end

    it "marks the queue as cancelled" do
      service.call
      expect(queue.reload.status).to eq("cancelled")
    end

    it "keeps the building at its current level" do
      service.call
      expect(building.reload.level).to eq(1)
    end

    it "refunds the upgrade cost" do
      cost = Buildings::Calculator.cost("solar_station", 2)
      service.call
      expect(planet.reload.metal_stock.to_f).to be_within(1).of(750 + cost[:metal])
    end
  end

  describe "#call — no pending queue" do
    it "returns failure with no_pending_queue" do
      result = service.call
      expect(result.success?).to be false
      expect(result.error).to eq("no_pending_queue")
    end

    it "does not modify planet resources" do
      service.call
      expect(planet.reload.metal_stock.to_f).to be_within(1).of(750)
    end
  end

  describe "#call — race condition (queue completed between check and lock)" do
    let(:building) { create(:building, planet: planet, building_type: "command_center", level: 1, slot_index: 0) }
    let!(:queue) do
      create(:construction_queue,
        planet:       planet,
        building:     building,
        target_level: 2,
        status:       "completed",
        started_at:   1.hour.ago,
        completes_at: Time.current)
    end

    it "returns failure" do
      result = service.call
      expect(result.success?).to be false
      expect(result.error).to eq("no_pending_queue")
    end

    it "does not refund resources" do
      initial_metal = planet.reload.metal_stock
      service.call
      expect(planet.reload.metal_stock.to_f).to be_within(1).of(initial_metal)
    end

    it "does not destroy the building" do
      service.call
      expect { building.reload }.not_to raise_error
    end
  end
end
