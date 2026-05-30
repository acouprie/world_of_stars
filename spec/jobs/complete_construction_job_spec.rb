require "rails_helper"

RSpec.describe CompleteConstructionJob, type: :job do
  let(:planet)   { create(:planet, :player, resources_updated_at: Time.current) }
  let(:building) { create(:building, planet: planet, building_type: "command_center", level: 1) }
  let(:queue) do
    create(:construction_queue,
      planet:       planet,
      building:     building,
      target_level: 2,
      status:       "pending",
      started_at:   1.hour.ago,
      completes_at: 1.second.ago)
  end

  before { planet.buildings.load }

  describe "#perform" do
    it "upgrades the building to target_level" do
      described_class.new.perform(queue.id)
      expect(building.reload.level).to eq(2)
    end

    it "marks the construction queue as completed" do
      described_class.new.perform(queue.id)
      expect(queue.reload.status).to eq("completed")
    end

    it "calculates and persists resources before upgrading" do
      planet.update!(metal_stock: 0, resources_updated_at: 1.hour.ago)
      create(:building, planet: planet, building_type: "metal_mine", level: 1)

      described_class.new.perform(queue.id)
      expect(planet.reload.metal_stock.to_f).to be > 0
    end

    it "is idempotent — running twice does not double-apply the upgrade" do
      described_class.new.perform(queue.id)
      described_class.new.perform(queue.id)
      expect(building.reload.level).to eq(2)
    end

    it "does nothing when queue is already completed" do
      queue.update!(status: "completed")
      described_class.new.perform(queue.id)
      expect(building.reload.level).to eq(1)
    end

    it "does nothing when queue is cancelled" do
      queue.update!(status: "cancelled")
      described_class.new.perform(queue.id)
      expect(building.reload.level).to eq(1)
    end

    it "does nothing for a non-existent queue ID" do
      expect { described_class.new.perform(99_999_999) }.not_to raise_error
    end
  end
end
