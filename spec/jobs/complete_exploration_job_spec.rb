require "rails_helper"

RSpec.describe CompleteExplorationJob, type: :job do
  let(:user)          { create(:user, exploration_xp: 0) }
  let(:planet)        { create(:planet, :player, user: user, resources_updated_at: Time.current) }
  let(:target_planet) { create(:planet) }

  let!(:mission) do
    create(:exploration_mission,
      planet:         planet,
      target_planet:  target_planet,
      status:         "pending",
      force_snapshot: { "sonde" => 3 },
      started_at:     30.minutes.ago,
      finishes_at:    Time.current)
  end

  let!(:sonde_unit) { create(:unit, planet: planet, unit_type: "sonde", count: 0) }

  def perform
    described_class.perform_now(mission.id)
  end

  before do
    allow(Explorations::Resolver).to receive(:new).and_return(
      instance_double(Explorations::Resolver, call: Explorations::Resolver::Result.new(
        exploration_points: 50,
        resources:          { metal: 100, food: 80, thorium: 40 },
        losses:             { "sonde" => 1 }
      ))
    )
  end

  describe "success" do
    it "marks the mission as completed" do
      perform
      expect(mission.reload.status).to eq("completed")
    end

    it "credits exploration XP to the user" do
      perform
      expect(user.reload.exploration_xp).to eq(50)
    end

    it "restores survivors to the source planet" do
      perform
      expect(sonde_unit.reload.count).to eq(2)
    end

    it "credits resources to the source planet" do
      perform
      planet.reload
      expect(planet.metal_stock).to   be >= 100
      expect(planet.food_stock).to    be >= 80
      expect(planet.thorium_stock).to be >= 40
    end

    it "caps resources at planet capacity" do
      planet.update!(metal_stock: planet.metal_capacity, food_stock: planet.food_capacity, thorium_stock: planet.thorium_capacity)
      perform
      planet.reload
      expect(planet.metal_stock).to   be <= planet.metal_capacity
      expect(planet.food_stock).to    be <= planet.food_capacity
      expect(planet.thorium_stock).to be <= planet.thorium_capacity
    end

    it "stores losses_snapshot on mission" do
      perform
      expect(mission.reload.losses_snapshot).to eq({ "sonde" => 1 })
    end
  end

  describe "idempotence" do
    it "does not credit XP twice when called twice" do
      perform
      perform
      expect(user.reload.exploration_xp).to eq(50)
    end
  end

  describe "already completed mission" do
    before { mission.update!(status: "completed") }

    it "is a no-op" do
      expect { perform }.not_to change { user.reload.exploration_xp }
    end
  end

  describe "missing mission" do
    it "is a no-op for nonexistent id" do
      expect { described_class.perform_now(0) }.not_to raise_error
    end
  end
end
