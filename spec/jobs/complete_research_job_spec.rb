require "rails_helper"

RSpec.describe CompleteResearchJob, type: :job do
  let(:planet) { create(:planet, :player, resources_updated_at: Time.current) }
  let!(:planet_tech) do
    create(:planet_technology, planet: planet, tech_key: "forage_cristallin", level: 0, status: "researching")
  end
  let(:queue) do
    create(:research_queue,
      planet:       planet,
      tech_key:     "forage_cristallin",
      target_level: 1,
      status:       "pending",
      started_at:   1.hour.ago,
      finishes_at:  1.second.ago,
      metal_cost:   800,
      food_cost:    480,
      thorium_cost: 320)
  end

  describe "#perform" do
    it "upgrades the technology to target_level" do
      described_class.new.perform(queue.id)
      expect(planet_tech.reload.level).to eq(1)
    end

    it "resets planet_technology status to idle" do
      described_class.new.perform(queue.id)
      expect(planet_tech.reload.status).to eq("idle")
    end

    it "marks the research queue as completed" do
      described_class.new.perform(queue.id)
      expect(queue.reload.status).to eq("completed")
    end

    it "is idempotent — running twice does not double-apply the upgrade" do
      described_class.new.perform(queue.id)
      described_class.new.perform(queue.id)
      expect(planet_tech.reload.level).to eq(1)
    end

    it "does nothing when queue is already completed" do
      queue.update!(status: "completed")
      described_class.new.perform(queue.id)
      expect(planet_tech.reload.level).to eq(0)
    end

    it "does nothing when queue is cancelled" do
      queue.update!(status: "cancelled")
      described_class.new.perform(queue.id)
      expect(planet_tech.reload.level).to eq(0)
    end

    it "does nothing for a non-existent queue ID" do
      expect { described_class.new.perform(99_999_999) }.not_to raise_error
    end
  end
end
