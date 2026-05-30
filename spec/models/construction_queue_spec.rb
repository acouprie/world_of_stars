require "rails_helper"

RSpec.describe ConstructionQueue, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:planet) }
    it { is_expected.to belong_to(:building) }
  end

  describe "validations" do
    subject { build(:construction_queue) }

    it { is_expected.to validate_inclusion_of(:status).in_array(ConstructionQueue::STATUSES) }
    it { is_expected.to validate_numericality_of(:target_level).is_greater_than(0).only_integer }

    it "is invalid when completes_at is before started_at" do
      queue = build(:construction_queue, started_at: 1.hour.from_now, completes_at: Time.current)
      expect(queue).not_to be_valid
      expect(queue.errors[:completes_at]).to be_present
    end

    it "is invalid when completes_at equals started_at" do
      t = Time.current
      queue = build(:construction_queue, started_at: t, completes_at: t)
      expect(queue).not_to be_valid
    end
  end

  describe "scopes" do
    let!(:pending_queue)   { create(:construction_queue, status: "pending") }
    let!(:completed_queue) { create(:construction_queue, status: "completed") }
    let!(:cancelled_queue) { create(:construction_queue, status: "cancelled") }

    it "pending scope returns only pending queues" do
      expect(ConstructionQueue.pending).to contain_exactly(pending_queue)
    end

    it "completed scope returns only completed queues" do
      expect(ConstructionQueue.completed).to contain_exactly(completed_queue)
    end

    it "cancelled scope returns only cancelled queues" do
      expect(ConstructionQueue.cancelled).to contain_exactly(cancelled_queue)
    end
  end

  describe "predicate methods" do
    it "#pending? returns true for pending status" do
      expect(build(:construction_queue, status: "pending").pending?).to be true
    end

    it "#completed? returns true for completed status" do
      expect(build(:construction_queue, status: "completed").completed?).to be true
    end

    it "#cancelled? returns true for cancelled status" do
      expect(build(:construction_queue, status: "cancelled").cancelled?).to be true
    end

    it "#pending? returns false for non-pending" do
      expect(build(:construction_queue, status: "completed").pending?).to be false
    end
  end
end
