require "rails_helper"

RSpec.describe CompleteCombatJob, type: :job do
  let(:attacker) { create(:user, combat_xp: 0) }
  let(:defender) { create(:user, combat_xp: 0) }
  let(:planet)        { create(:planet, :player, user: attacker, resources_updated_at: Time.current) }
  let(:target_planet) { create(:planet, :player, user: defender, resources_updated_at: Time.current) }

  let!(:mission) do
    create(:combat_mission,
      planet:         planet,
      target_planet:  target_planet,
      status:         "traveling",
      attacker_force: { "maraudeur" => 10 },
      started_at:     1.hour.ago,
      arrives_at:     Time.current)
  end

  let!(:attacker_unit) { create(:unit, planet: planet, unit_type: "maraudeur", count: 0) }
  let!(:defender_unit) { create(:unit, planet: target_planet, unit_type: "sentinelle", count: 5) }

  def perform
    described_class.perform_now(mission.id)
  end

  def stub_resolver(outcome:, attacker_losses: {}, defender_losses: {}, pillage_capacity: 0, xp: { attacker: 0, defender: 0 })
    result = Combats::Resolver::Result.new(
      outcome:          outcome,
      rounds_log:       [{ round: 1, attacker: {}, defender: {} }],
      losses:           { attacker: attacker_losses, defender: defender_losses },
      xp:               xp,
      pillage_capacity: pillage_capacity
    )
    allow(Combats::Resolver).to receive(:new).and_return(instance_double(Combats::Resolver, call: result))
  end

  describe "attacker victory" do
    before do
      stub_resolver(
        outcome:          :attacker_wins,
        attacker_losses:  { maraudeur: 2 },
        defender_losses:  { sentinelle: 5 },
        pillage_capacity: 300,
        xp:               { attacker: 500, defender: 0 }
      )
    end

    it "applies defender losses to the target planet's units" do
      perform
      expect(defender_unit.reload.count).to eq(0)
    end

    it "restitutes attacker survivors to the source planet" do
      perform
      expect(attacker_unit.reload.count).to eq(8)
    end

    it "credits pillaged resources to the source planet" do
      planet.update!(metal_stock: 0, food_stock: 0, thorium_stock: 0)
      target_planet.update!(metal_stock: 1000, food_stock: 1000, thorium_stock: 1000)
      perform
      planet.reload
      expect(planet.metal_stock).to be > 0
    end

    it "deducts pillaged resources from the target planet" do
      target_planet.update!(metal_stock: 1000, food_stock: 1000, thorium_stock: 1000)
      perform
      target_planet.reload
      expect(target_planet.metal_stock).to be < 1000
    end

    it "increments combat_xp on both players" do
      perform
      expect(attacker.reload.combat_xp).to eq(500)
    end

    it "sets outcome to attacker_wins" do
      perform
      expect(mission.reload.outcome).to eq("attacker_wins")
    end
  end

  describe "defender victory" do
    before do
      stub_resolver(
        outcome:          :defender_holds,
        attacker_losses:  { maraudeur: 10 },
        defender_losses:  {},
        pillage_capacity: 0,
        xp:               { attacker: 0, defender: 300 }
      )
    end

    it "does not pillage any resources" do
      target_planet.update!(metal_stock: 1000)
      perform
      expect(mission.reload.metal_pillaged).to eq(0)
    end

    it "preserves defender survivors" do
      perform
      expect(defender_unit.reload.count).to eq(5)
    end

    it "sets outcome to defender_holds" do
      perform
      expect(mission.reload.outcome).to eq("defender_holds")
    end
  end

  describe "idempotence" do
    before do
      stub_resolver(outcome: :attacker_wins, defender_losses: { sentinelle: 5 }, xp: { attacker: 100, defender: 0 })
    end

    it "applies losses and XP only once when run twice" do
      perform
      perform
      expect(attacker.reload.combat_xp).to eq(100)
    end

    it "does not re-resolve an already completed mission" do
      perform
      expect(Combats::Resolver).not_to receive(:new)
      perform
    end
  end

  describe "already completed mission" do
    before do
      mission.update!(status: "completed")
    end

    it "is a no-op" do
      expect(Combats::Resolver).not_to receive(:new)
      expect { perform }.not_to change { attacker.reload.combat_xp }
    end
  end

  describe "missing mission" do
    it "is a no-op for nonexistent id" do
      expect { described_class.perform_now(0) }.not_to raise_error
    end
  end

  describe "pillage capped by transport" do
    it "limits pillage to the attacker's surviving transport capacity" do
      stub_resolver(outcome: :attacker_wins, pillage_capacity: 60, xp: { attacker: 0, defender: 0 })
      target_planet.update!(metal_stock: 1000, food_stock: 1000, thorium_stock: 1000)
      perform
      expect(mission.reload.metal_pillaged).to eq(20)
    end
  end

  describe "pillage capped by target resources" do
    it "limits pillage to what the target planet actually has" do
      stub_resolver(outcome: :attacker_wins, pillage_capacity: 3000, xp: { attacker: 0, defender: 0 })
      target_planet.update!(metal_stock: 10, food_stock: 10, thorium_stock: 10)
      perform
      expect(mission.reload.metal_pillaged).to eq(10)
    end
  end
end
