require "rails_helper"

RSpec.describe Trainings::InitiateService do
  # Default planet factory stocks (1_000 metal, 1_000 food, 500 thorium) are intentionally
  # within the default storage capacity (1_000 per resource, no warehouse built), so
  # calculate_resources! inside the service lock does not clamp them unexpectedly.
  let(:planet) do
    create(:planet, :player, resources_updated_at: Time.current)
  end

  let!(:training_camp)  { create(:building, planet: planet, building_type: "training_camp",  level: 1, slot_index: 1) }
  let!(:military_camp)  { create(:building, planet: planet, building_type: "military_camp",  level: 1, slot_index: 2) }

  before { planet.buildings.load }

  def call(unit_type: "maraudeur", quantity: 1)
    described_class.new(planet, unit_type, quantity).call
  end

  describe "success" do
    it "returns a successful result" do
      expect(call.success?).to be true
    end

    it "creates a pending training queue" do
      call
      expect(planet.training_queues.pending.count).to eq(1)
    end

    it "debits resources at enqueue time" do
      cost = Units.cost_for(:maraudeur)
      before_metal = planet.metal_stock.to_f
      before_food  = planet.food_stock.to_f
      call
      expect(planet.reload.metal_stock.to_f).to be_within(0.01).of(before_metal - cost[:metal])
      expect(planet.reload.food_stock.to_f).to  be_within(0.01).of(before_food  - cost[:food])
    end

    it "debits proportionally for quantity > 1" do
      cost         = Units.cost_for(:maraudeur)
      before_metal = planet.metal_stock.to_f
      call(quantity: 3)
      expect(planet.reload.metal_stock.to_f).to be_within(0.01).of(before_metal - cost[:metal] * 3)
    end
  end

  describe "training time" do
    it "uses base_time at training_camp level 1" do
      result = call
      queue  = result.queue
      duration = queue.completes_at - queue.started_at
      expect(duration.to_i).to eq(Units::REGISTRY[:maraudeur][:base_time])
    end

    it "applies the 0.95 coefficient per training_camp level" do
      training_camp.update!(level: 3)
      planet.buildings.reset
      planet.buildings.load
      result   = call
      queue    = result.queue
      expected = (Units::REGISTRY[:maraudeur][:base_time] * 0.95**2).ceil
      expect((queue.completes_at - queue.started_at).to_i).to eq(expected)
    end

    it "scales duration by quantity" do
      result   = call(quantity: 5)
      queue    = result.queue
      per_unit = Units.training_time(:maraudeur, 1)
      expect((queue.completes_at - queue.started_at).to_i).to eq(per_unit * 5)
    end
  end

  describe "prerequisite: training_camp required for all units" do
    it "fails when no training_camp is built" do
      training_camp.destroy!
      planet.buildings.reset
      planet.buildings.load
      expect(call.success?).to be false
      expect(call.error).to eq("prerequisite_missing")
    end
  end

  describe "prerequisite: military_camp level" do
    it "fails for maraudeur when military_camp is level 0" do
      military_camp.update!(level: 0)
      planet.buildings.reset
      planet.buildings.load
      expect(call.success?).to be false
      expect(call.error).to eq("prerequisite_missing")
    end

    it "fails for mule when military_camp < 2" do
      result = described_class.new(planet, "mule", 1).call
      expect(result.success?).to be false
      expect(result.error).to eq("prerequisite_missing")
    end

    it "succeeds for mule when military_camp >= 2" do
      military_camp.update!(level: 2)
      planet.buildings.reset
      planet.buildings.load
      result = described_class.new(planet, "mule", 1).call
      expect(result.success?).to be true
    end

    it "fails for regulier when military_camp < 3" do
      result = described_class.new(planet, "regulier", 1).call
      expect(result.success?).to be false
    end

    it "fails for sentinelle when military_camp < 5" do
      result = described_class.new(planet, "sentinelle", 1).call
      expect(result.success?).to be false
    end

    it "fails for spectre when military_camp < 6" do
      result = described_class.new(planet, "spectre", 1).call
      expect(result.success?).to be false
    end
  end

  describe "prerequisite: technology" do
    it "fails for regulier when armement technology is not researched (stub returns 0)" do
      military_camp.update!(level: 3)
      planet.buildings.reset
      planet.buildings.load
      result = described_class.new(planet, "regulier", 1).call
      expect(result.success?).to be false
      expect(result.error).to eq("prerequisite_missing")
    end

    it "succeeds for regulier when armement is stubbed to level >= 1" do
      military_camp.update!(level: 3)
      planet.buildings.reset
      planet.buildings.load
      # with_lock reloads the planet and clears the user association cache, so stub any User.
      # The block handles all keys: armement → 1, everything else → 0.
      allow_any_instance_of(User).to receive(:technology_level) { |_, key| key == :armement ? 1 : 0 }
      result = described_class.new(planet, "regulier", 1).call
      expect(result.success?).to be true
    end

    it "fails for sentinelle without blindage_tactique" do
      military_camp.update!(level: 5)
      planet.buildings.reset
      planet.buildings.load
      result = described_class.new(planet, "sentinelle", 1).call
      expect(result.success?).to be false
    end

    it "fails for spectre without guerre_electronique" do
      military_camp.update!(level: 6)
      planet.buildings.reset
      planet.buildings.load
      result = described_class.new(planet, "spectre", 1).call
      expect(result.success?).to be false
    end
  end

  describe "prerequisite: research_lab for scientifique" do
    it "fails when no research_lab is built" do
      result = described_class.new(planet, "scientifique", 1).call
      expect(result.success?).to be false
      expect(result.error).to eq("prerequisite_missing")
    end

    it "succeeds when research_lab >= 1 is built" do
      create(:building, planet: planet, building_type: "research_lab", level: 1, slot_index: 3)
      planet.buildings.reset
      planet.buildings.load
      result = described_class.new(planet, "scientifique", 1).call
      expect(result.success?).to be true
    end
  end

  describe "insufficient resources" do
    it "fails when the planet cannot afford the cost" do
      planet.update!(metal_stock: 0, food_stock: 0, thorium_stock: 0)
      expect(call.success?).to be false
      expect(call.error).to eq("insufficient_resources")
    end

    it "does not deduct food when metal is insufficient" do
      # Set metal to 0 so the service returns :insufficient_resources before deducting food.
      # Food stays at whatever calculate_resources! sets it to (within capacity, unchanged).
      planet.update!(metal_stock: 0)
      food_after_calculate = planet.food_stock.to_f  # already within capacity, no change expected
      call
      expect(planet.reload.food_stock.to_f).to be_within(0.01).of(food_after_calculate)
    end
  end

  describe "queue capacity (chaine_de_production technology)" do
    it "fails with queue_full when default slot is occupied" do
      call
      expect(call.error).to eq("queue_full")
    end

    it "allows a second queue when chaine_de_production returns level >= 1" do
      # with_lock reloads the planet and clears the user association cache, so stub any User.
      # The block handles all keys: chaine_de_production → 1, everything else → 0.
      allow_any_instance_of(User).to receive(:technology_level) { |_, key| key == :chaine_de_production ? 1 : 0 }
      call
      result2 = described_class.new(planet, "maraudeur", 1).call
      expect(result2.success?).to be true
    end
  end

  describe "validation" do
    it "fails for unknown unit type" do
      result = described_class.new(planet, "laser_cannon", 1).call
      expect(result.success?).to be false
    end

    it "fails for quantity <= 0" do
      expect(call(quantity: 0).success?).to be false
    end
  end
end
