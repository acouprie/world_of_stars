require "rails_helper"

RSpec.describe TrainingQueue, type: :model do
  let(:planet) { create(:planet, :player) }

  describe "validations" do
    it "is valid with correct attributes" do
      expect(build(:training_queue, planet: planet)).to be_valid
    end

    it "is invalid for an unknown unit_type" do
      expect(build(:training_queue, planet: planet, unit_type: "laser_cannon")).not_to be_valid
    end

    it "is invalid with quantity <= 0" do
      expect(build(:training_queue, planet: planet, quantity: 0)).not_to be_valid
    end

    it "is invalid with an unknown status" do
      expect(build(:training_queue, planet: planet, status: "unknown")).not_to be_valid
    end

    it "is invalid when completes_at is not after started_at" do
      now = Time.current
      expect(build(:training_queue, planet: planet, started_at: now, completes_at: now)).not_to be_valid
    end
  end

  describe "status predicates" do
    it "pending? returns true for pending status" do
      expect(build(:training_queue, status: "pending")).to be_pending
    end

    it "completed? returns true for completed status" do
      expect(build(:training_queue, status: "completed", completes_at: 1.hour.ago)).to be_completed
    end
  end
end
