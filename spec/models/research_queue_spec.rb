require "rails_helper"

RSpec.describe ResearchQueue, type: :model do
  let(:planet) { create(:planet, :player) }

  describe "associations" do
    it { is_expected.to belong_to(:planet) }
  end

  describe "validations" do
    subject { build(:research_queue, planet: planet) }

    it { is_expected.to validate_inclusion_of(:status).in_array(ResearchQueue::STATUSES) }
    it { is_expected.to validate_numericality_of(:target_level).is_greater_than(0).only_integer }

    it "is invalid when completes_at is before started_at" do
      queue = build(:research_queue, planet: planet, started_at: 1.hour.from_now, completes_at: Time.current)
      expect(queue).not_to be_valid
      expect(queue.errors[:completes_at]).to be_present
    end

    it "is invalid when completes_at equals started_at" do
      t = Time.current
      queue = build(:research_queue, planet: planet, started_at: t, completes_at: t)
      expect(queue).not_to be_valid
    end

    it "is invalid when a research is already pending for the planet" do
      create(:research_queue, planet: planet, status: "pending")
      queue = build(:research_queue, planet: planet, status: "pending")
      expect(queue).not_to be_valid
      expect(queue.errors[:base]).to be_present
    end

    it "allows multiple non-pending queues for the same planet" do
      create(:research_queue, planet: planet, status: "completed")
      queue = build(:research_queue, planet: planet, status: "completed")
      expect(queue).to be_valid
    end
  end

  describe "scopes" do
    let!(:pending_queue)   { create(:research_queue, planet: planet, status: "pending") }
    let!(:completed_queue) { create(:research_queue, planet: create(:planet, :player), status: "completed") }
    let!(:cancelled_queue) { create(:research_queue, planet: create(:planet, :player), status: "cancelled") }

    it "pending scope returns only pending queues" do
      expect(ResearchQueue.pending).to contain_exactly(pending_queue)
    end

    it "completed scope returns only completed queues" do
      expect(ResearchQueue.completed).to contain_exactly(completed_queue)
    end

    it "cancelled scope returns only cancelled queues" do
      expect(ResearchQueue.cancelled).to contain_exactly(cancelled_queue)
    end
  end

  describe "predicate methods" do
    it "#pending? returns true for pending status" do
      expect(build(:research_queue, status: "pending")).to be_pending
    end

    it "#completed? returns true for completed status" do
      expect(build(:research_queue, status: "completed")).to be_completed
    end

    it "#cancelled? returns true for cancelled status" do
      expect(build(:research_queue, status: "cancelled")).to be_cancelled
    end

    it "#pending? returns false for non-pending" do
      expect(build(:research_queue, status: "completed")).not_to be_pending
    end
  end
end
