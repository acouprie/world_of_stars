require "rails_helper"

RSpec.describe CompleteTrainingJob, type: :job do
  let(:planet) { create(:planet, :player, resources_updated_at: Time.current) }
  let!(:military_camp)  { create(:building, planet: planet, building_type: "military_camp",  level: 1, slot_index: 1) }
  let!(:training_camp)  { create(:building, planet: planet, building_type: "training_camp",  level: 1, slot_index: 2) }

  let(:queue) do
    create(:training_queue,
      planet:      planet,
      unit_type:   "maraudeur",
      quantity:    5,
      status:      "pending",
      started_at:  1.hour.ago,
      completes_at: 1.second.ago)
  end

  before { planet.buildings.load }

  describe "#perform" do
    it "increments units count by the queued quantity" do
      described_class.new.perform(queue.id)
      unit = planet.units.find_by(unit_type: "maraudeur")
      expect(unit.count).to eq(5)
    end

    it "accumulates on existing units" do
      create(:unit, planet: planet, unit_type: "maraudeur", count: 10)
      described_class.new.perform(queue.id)
      expect(planet.units.find_by(unit_type: "maraudeur").count).to eq(15)
    end

    it "marks the training queue as completed" do
      described_class.new.perform(queue.id)
      expect(queue.reload.status).to eq("completed")
    end

    it "is idempotent — running twice does not double-count" do
      described_class.new.perform(queue.id)
      described_class.new.perform(queue.id)
      expect(planet.units.find_by(unit_type: "maraudeur").count).to eq(5)
    end

    it "does nothing when queue is already completed" do
      queue.update!(status: "completed")
      described_class.new.perform(queue.id)
      expect(planet.units.where(unit_type: "maraudeur").count).to eq(0)
    end

    it "does nothing for a non-existent queue ID" do
      expect { described_class.new.perform(99_999_999) }.not_to raise_error
    end
  end
end
