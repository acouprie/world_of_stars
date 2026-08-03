require "rails_helper"

RSpec.describe Combats::StartService do
  let(:attacker) { create(:user) }
  let(:defender) { create(:user) }
  let(:planet)        { create(:planet, :player, user: attacker, resources_updated_at: Time.current) }
  let(:target_planet) { create(:planet, :player, user: defender, resources_updated_at: Time.current) }

  let!(:source_portal) { create(:building, planet: planet, building_type: "quantum_portal", level: 1, slot_index: 1) }
  let!(:target_portal) { create(:building, planet: target_planet, building_type: "quantum_portal", level: 1, slot_index: 1) }
  let!(:maraudeur_unit) { create(:unit, planet: planet, unit_type: "maraudeur", count: 10) }

  before do
    planet.buildings.load
    target_planet.buildings.load
  end

  def call(force: { maraudeur: 5 }, target: target_planet)
    described_class.call(planet: planet, target_planet: target, force: force)
  end

  describe "success" do
    it "returns a successful result" do
      expect(call.success?).to be true
    end

    it "creates a traveling mission" do
      call
      expect(planet.combat_missions.traveling.count).to eq(1)
    end

    it "deducts units from the source planet" do
      call
      expect(maraudeur_unit.reload.count).to eq(5)
    end

    it "stores attacker_force with string keys" do
      result = call(force: { maraudeur: 5 })
      expect(result.mission.attacker_force).to eq({ "maraudeur" => 5 })
    end

    it "sets arrives_at exactly 1 hour after started_at" do
      result  = call
      mission = result.mission
      expect(mission.arrives_at).to eq(mission.started_at + 1.hour)
    end

    it "schedules CompleteCombatJob" do
      expect { call }.to have_enqueued_job(CompleteCombatJob)
    end
  end

  describe "no quantum portal on source planet" do
    it "returns :no_quantum_portal_source" do
      source_portal.destroy!
      planet.buildings.reset
      result = call
      expect(result.success?).to be false
      expect(result.error).to eq(:no_quantum_portal_source)
    end
  end

  describe "no quantum portal on target planet" do
    it "returns :no_quantum_portal_target" do
      target_portal.destroy!
      target_planet.buildings.reset
      result = call
      expect(result.success?).to be false
      expect(result.error).to eq(:no_quantum_portal_target)
    end
  end

  describe "attacking own planet" do
    it "returns :cannot_attack_own_planet" do
      own_planet = create(:planet, :player, user: attacker)
      create(:building, planet: own_planet, building_type: "quantum_portal", level: 1, slot_index: 1)
      own_planet.buildings.reset
      result = call(target: own_planet)
      expect(result.success?).to be false
      expect(result.error).to eq(:cannot_attack_own_planet)
    end
  end

  describe "empty force" do
    it "returns :empty_force when force is {}" do
      result = call(force: {})
      expect(result.success?).to be false
      expect(result.error).to eq(:empty_force)
    end

    it "returns :empty_force when all quantities are 0" do
      result = call(force: { maraudeur: 0 })
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
      result = call(force: { maraudeur: 20 })
      expect(result.success?).to be false
      expect(result.error).to eq(:insufficient_units)
    end

    it "does not deduct any units on partial failure" do
      create(:unit, planet: planet, unit_type: "sentinelle", count: 0)
      planet.units.reset
      result = call(force: { maraudeur: 5, sentinelle: 1 })
      expect(result.success?).to be false
      expect(maraudeur_unit.reload.count).to eq(10)
    end
  end
end
