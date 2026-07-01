require "rails_helper"

RSpec.describe Explorations::StartService do
  let(:user)          { create(:user) }
  let(:planet)        { create(:planet, :player, user: user, resources_updated_at: Time.current) }
  let(:target_planet) { create(:planet) }

  let!(:quantum_portal) { create(:building, planet: planet, building_type: "quantum_portal", level: 1, slot_index: 1) }
  let!(:sonde_unit)     { create(:unit, planet: planet, unit_type: "sonde", count: 5) }

  before { planet.buildings.load }

  def call(force: { sonde: 2 }, target: target_planet)
    described_class.call(planet: planet, target_planet: target, force: force)
  end

  describe "success" do
    it "returns a successful result" do
      expect(call.success?).to be true
    end

    it "creates a pending mission" do
      call
      expect(planet.exploration_missions.pending.count).to eq(1)
    end

    it "deducts units from the source planet" do
      call
      expect(sonde_unit.reload.count).to eq(3)
    end

    it "stores force_snapshot with string keys" do
      result = call(force: { sonde: 2 })
      expect(result.mission.force_snapshot).to eq({ "sonde" => 2 })
    end

    it "schedules CompleteExplorationJob" do
      expect { call }.to have_enqueued_job(CompleteExplorationJob)
    end

    it "sets finishes_at roughly 20 + total_units minutes after started_at" do
      result   = call(force: { sonde: 2 })
      mission  = result.mission
      duration = mission.finishes_at - mission.started_at
      expect(duration).to be_within(2).of(22.minutes)
    end
  end

  describe "no quantum portal" do
    it "returns :no_quantum_portal error" do
      quantum_portal.destroy!
      planet.buildings.reset
      planet.buildings.load
      result = call
      expect(result.success?).to be false
      expect(result.error).to eq(:no_quantum_portal)
    end
  end

  describe "target planet not empty" do
    it "returns :target_not_empty for player planets" do
      player_planet = create(:planet, :player)
      result = call(target: player_planet)
      expect(result.success?).to be false
      expect(result.error).to eq(:target_not_empty)
    end
  end

  describe "empty force" do
    it "returns :empty_force when force is {}" do
      result = call(force: {})
      expect(result.success?).to be false
      expect(result.error).to eq(:empty_force)
    end

    it "returns :empty_force when all quantities are 0" do
      result = call(force: { sonde: 0 })
      expect(result.success?).to be false
      expect(result.error).to eq(:empty_force)
    end
  end

  describe "invalid unit type" do
    it "returns :invalid_unit_type for unknown unit" do
      result = call(force: { laser_cannon: 1 })
      expect(result.success?).to be false
      expect(result.error).to eq(:invalid_unit_type)
    end
  end

  describe "insufficient units" do
    it "returns :insufficient_units when requesting more than available" do
      result = call(force: { sonde: 10 })
      expect(result.success?).to be false
      expect(result.error).to eq(:insufficient_units)
    end

    it "does not deduct any units on partial failure" do
      create(:unit, planet: planet, unit_type: "maraudeur", count: 0)
      planet.units.reset
      result = call(force: { sonde: 2, maraudeur: 1 })
      expect(result.success?).to be false
      expect(sonde_unit.reload.count).to eq(5)
    end
  end

  describe "max simultaneous missions" do
    it "returns :max_simultaneous_reached when 5 missions are already pending" do
      target_planets = create_list(:planet, 5)
      target_planets.each do |tp|
        create(:exploration_mission, planet: planet, target_planet: tp)
      end
      result = call
      expect(result.success?).to be false
      expect(result.error).to eq(:max_simultaneous_reached)
    end
  end
end
