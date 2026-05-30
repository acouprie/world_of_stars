require "rails_helper"

RSpec.describe Constructions::InitiateService do
  let(:user)   { create(:user) }
  # Resources within default storage capacity (1_000) so calculate_resources! doesn't cap them unexpectedly.
  let(:planet) do
    create(:planet, :player, user: user,
      metal_stock:          800,
      food_stock:           800,
      thorium_stock:        400,
      resources_updated_at: Time.current)
  end

  subject(:service) { described_class.new(planet, :command_center) }

  describe "#call — building command_center (no prerequisite)" do
    it "returns success" do
      result = service.call
      expect(result.success?).to be true
    end

    it "creates a construction queue on the planet" do
      service.call
      expect(planet.reload.construction_queue).to be_present
    end

    it "creates a Building record for the planet" do
      expect { service.call }.to change { planet.buildings.count }.by(1)
    end

    it "deducts metal cost from planet stock" do
      cost = Buildings::Calculator.cost(:command_center, 1)
      service.call
      expect(planet.reload.metal_stock.to_f).to be_within(1).of(800 - cost[:metal])
    end

    it "deducts food cost from planet stock" do
      cost = Buildings::Calculator.cost(:command_center, 1)
      service.call
      expect(planet.reload.food_stock.to_f).to be_within(1).of(800 - cost[:food])
    end

    it "schedules a CompleteConstructionJob" do
      expect { service.call }.to have_enqueued_job(CompleteConstructionJob)
    end

    it "sets the queue status to pending" do
      service.call
      expect(planet.reload.construction_queue.status).to eq("pending")
    end

    it "sets completes_at in the future" do
      service.call
      expect(planet.reload.construction_queue.completes_at).to be > Time.current
    end
  end

  describe "#call — upgrading an existing building" do
    # solar_station level 2 costs: metal=75, food=37, thorium=0 — affordable within default capacity.
    before do
      create(:building, planet: planet, building_type: "command_center",  level: 1)
      create(:building, planet: planet, building_type: "solar_station",   level: 1)
    end

    it "targets level 2 for the existing building" do
      result = described_class.new(planet, :solar_station).call
      expect(result.success?).to be true
      expect(planet.reload.construction_queue.target_level).to eq(2)
    end
  end

  describe "#call — prerequisite_missing" do
    it "returns failure when building needs command_center but none exists" do
      result = described_class.new(planet, :solar_station).call
      expect(result.success?).to be false
      expect(result.error).to eq("prerequisite_missing")
    end

    it "succeeds once command_center is at level 1" do
      create(:building, planet: planet, building_type: "command_center", level: 1)
      # solar_station costs: metal:75, food:30, thorium:0 at level 1
      result = described_class.new(planet, :solar_station).call
      expect(result.success?).to be true
    end
  end

  describe "#call — already_building" do
    before { service.call }

    it "returns failure when a construction is already pending" do
      result = described_class.new(planet, :command_center).call
      expect(result.success?).to be false
      expect(result.error).to eq("already_building")
    end
  end

  describe "#call — insufficient_resources" do
    before { planet.update!(metal_stock: 0, food_stock: 0, thorium_stock: 0) }

    it "returns failure" do
      result = service.call
      expect(result.success?).to be false
      expect(result.error).to eq("insufficient_resources")
    end

    it "does not create a construction queue" do
      service.call
      expect(planet.reload.construction_queue).to be_nil
    end
  end

  describe "#call — insufficient_energy" do
    # command_center at level 1, no energy producer → net_energy = 0
    # metal_mine needs 10 energy → additional_energy = 10 → fails
    before do
      create(:building, planet: planet, building_type: "command_center", level: 1)
    end

    it "returns failure when net energy would go negative" do
      result = described_class.new(planet, :metal_mine).call
      expect(result.success?).to be false
      expect(result.error).to eq("insufficient_energy")
    end
  end

  describe "#call — unknown building type" do
    it "returns failure with an error message" do
      result = described_class.new(planet, :laser_cannon).call
      expect(result.success?).to be false
      expect(result.error).to include("Unknown building type")
    end
  end
end
