require "rails_helper"

RSpec.describe Explorations::Resolver do
  def resolve(force, context = {})
    described_class.new(force, context).call
  end

  # ── Determinism ────────────────────────────────────────────────────────────

  it "produces identical results for the same seed" do
    r1 = resolve({ scientifique: 5, sonde: 3 }, seed: 42)
    r2 = resolve({ scientifique: 5, sonde: 3 }, seed: 42)
    expect(r1.exploration_points).to eq(r2.exploration_points)
    expect(r1.resources).to        eq(r2.resources)
    expect(r1.losses).to           eq(r2.losses)
  end

  it "produces different results for different seeds" do
    points = (1..20).map { |s| resolve({ scientifique: 5, sonde: 3 }, seed: s).exploration_points }
    expect(points.uniq.size).to be > 1
  end

  # ── Result structure ───────────────────────────────────────────────────────

  it "returns a Result with exploration_points, resources, losses" do
    r = resolve({ maraudeur: 10 }, seed: 1)
    expect(r).to respond_to(:exploration_points, :resources, :losses)
    expect(r.resources.keys).to contain_exactly(:metal, :food, :thorium)
  end

  # ── XP base (exploration_magnitude_v1 §1: XP_BASES per unit type) ─────────

  it "XP is 0 for mule-only team (mule XP_BASE = 0)" do
    100.times do |seed|
      r = resolve({ mule: 10 }, seed: seed)
      expect(r.exploration_points).to eq(0)
    end
  end

  it "XP scales with scientifique count (XP_BASE 60 vs sonde 25)" do
    xp_without = (1..30).map { |s| resolve({ sonde: 5 }, seed: s).exploration_points }
    xp_with    = (1..30).map { |s| resolve({ scientifique: 5, sonde: 5 }, seed: s).exploration_points }
    expect(xp_with.sum).to be > xp_without.sum
  end

  it "XP is always non-negative" do
    10.times do |seed|
      r = resolve({ scientifique: 3, maraudeur: 5, mule: 2 }, seed: seed)
      expect(r.exploration_points).to be >= 0
    end
  end

  it "cartographie_stellaire level boosts XP via carto_xp_bonus (+4%/level)" do
    xp_base = (1..50).sum { |s| resolve({ scientifique: 5 }, seed: s).exploration_points }
    xp_carto = (1..50).sum { |s| resolve({ scientifique: 5 }, { seed: s, carto_level: 10 }).exploration_points }
    expect(xp_carto).to be > xp_base
  end

  # ── Resources ─────────────────────────────────────────────────────────────

  it "resources are always non-negative" do
    20.times do |seed|
      r = resolve({ sonde: 5, maraudeur: 5 }, seed: seed)
      expect(r.resources[:metal]).to   be >= 0
      expect(r.resources[:food]).to    be >= 0
      expect(r.resources[:thorium]).to be >= 0
    end
  end

  it "spectre-only team (transport 0) always gets zero resources (capped by transport)" do
    20.times do |seed|
      r = resolve({ spectre: 10 }, seed: seed)
      expect(r.resources[:metal]).to   eq(0)
      expect(r.resources[:food]).to    eq(0)
      expect(r.resources[:thorium]).to eq(0)
    end
  end

  it "resources per type never exceed team transport capacity" do
    20.times do |seed|
      force = { sonde: 2 }  # transport cap = 2 × 150 = 300
      r = resolve(force, seed: seed)
      transport_cap = 2 * Units::REGISTRY[:sonde][:stats][:transport]
      expect(r.resources[:metal]).to   be <= transport_cap
      expect(r.resources[:food]).to    be <= transport_cap
      expect(r.resources[:thorium]).to be <= transport_cap
    end
  end

  it "mule team unlocks large resources (high transport cap)" do
    results = (1..50).map { |s| resolve({ mule: 10 }, seed: s) }
    any_resources = results.any? { |r| r.resources[:metal] > 0 }
    expect(any_resources).to be true
  end

  it "combat units generate no loot (loot base excludes combat units)" do
    # A combat-only team has loot_base = 0, so resources are always zero regardless of transport.
    100.times do |seed|
      r = resolve({ maraudeur: 20 }, seed: seed)
      expect(r.resources[:metal]).to   eq(0)
      expect(r.resources[:food]).to    eq(0)
      expect(r.resources[:thorium]).to eq(0)
    end
  end

  # ── Losses ────────────────────────────────────────────────────────────────

  it "losses are always non-negative and never exceed force size" do
    20.times do |seed|
      force = { maraudeur: 5, sonde: 3, mule: 2 }
      r = resolve(force, seed: seed)
      r.losses.each do |type, n|
        expect(n).to be > 0
        expect(n).to be <= force[type]
      end
    end
  end

  it "loss tier none occurs in majority of missions (§7: 55%)" do
    no_loss_count = 200.times.count { |s| resolve({ sonde: 200 }, seed: s).losses.empty? }
    expect(no_loss_count).to be_between(90, 130)
  end

  it "critical loss tier (~2%) can wipe most of the team" do
    results = 500.times.map { |s| resolve({ sonde: 100 }, seed: s) }
    # Critical tier applies f directly (no weight modifiers): 60-100% of 100 = 60-100 losses
    wipeout = results.select { |r| r.losses.values.sum >= 60 }
    expect(wipeout.size).to be_between(2, 25)
  end

  it "escort reduces non-combat unit losses (§7: combat share applies escort_mult)" do
    seeds = 200
    # 20 sondes, no escort: losses = f × 0.6 × 20
    sonde_loss_base = seeds.times.sum { |s|
      resolve({ sonde: 20 }, seed: s).losses.fetch(:sonde, 0)
    }.to_f / seeds
    # 20 sondes + 30 sentinelles: combat_ratio=0.6 → escort_mult=0.7 → sonde losses × 0.7
    sonde_loss_escorted = seeds.times.sum { |s|
      resolve({ sonde: 20, sentinelle: 30 }, seed: s).losses.fetch(:sonde, 0)
    }.to_f / seeds
    expect(sonde_loss_escorted).to be < sonde_loss_base
  end

  it "recon units (sonde/spectre) suffer proportionally fewer losses than combat units (§7: w=0.6 vs 1.1)" do
    results = 100.times.map { |s| resolve({ maraudeur: 50, sonde: 50 }, seed: s) }
    results_with_losses = results.reject { |r| r.losses.empty? }
    skip "no missions with losses" if results_with_losses.empty?

    ratio_recon  = results_with_losses.sum { |r| r.losses.fetch(:sonde, 0).to_f / 50 }
    ratio_combat = results_with_losses.sum { |r| r.losses.fetch(:maraudeur, 0).to_f / 50 }
    expect(ratio_recon).to be < ratio_combat
  end

  it "critical tier ignores all modifiers — even escorted teams can be wiped" do
    # High escort ratio: 5 sondes + 95 sentinelles (escort_mult would be ~0.525 in non-crit).
    # Critical tier must still apply full fraction to all units regardless.
    results = 500.times.map { |s| resolve({ sonde: 5, sentinelle: 95 }, seed: s) }
    # At least one critical event should wipe >= 60% of the team (60+ out of 100)
    wipeout = results.select { |r| r.losses.values.sum >= 60 }
    expect(wipeout.size).to be_between(2, 25)
  end

  # ── Calibration — §7 property: E[loot] ≤ E[cost_of_losses] ──────────────────

  it "E[loot] ≤ E[cost_of_losses] for standard compositions (§7 anti-pump, ratios 0.39–0.83 at k=5)" do
    # Large armies (50+ per type) avoid rounding quantisation bias on per-type losses.
    # n=3000 keeps variance tight: theoretical ratios are 0.57–0.83, well below 1.0.
    n = 3_000
    [
      { sonde: 50 },
      { mule: 50 },
      { scientifique: 50, maraudeur: 50, sonde: 50 }
    ].each do |force|
      total_loot      = 0.0
      total_loss_cost = 0.0
      n.times do |seed|
        r = resolve(force, seed: seed)
        total_loot += r.resources.values.sum.to_f
        r.losses.each { |type, lost| total_loss_cost += Units.cost_for(type).values.sum * lost }
      end
      ratio = total_loss_cost > 0 ? (total_loot / total_loss_cost) : 0.0
      expect(ratio).to be <= 1.0, "Expected E[loot] ≤ E[losses] for #{force}, got ratio #{ratio.round(3)}"
    end
  end

  # ── String key normalisation ───────────────────────────────────────────────

  it "accepts string keys" do
    r = resolve({ "sonde" => 5 }, seed: 1)
    expect(r).to respond_to(:exploration_points)
  end

  it "ignores zero-count entries" do
    r1 = resolve({ sonde: 5 }, seed: 7)
    r2 = resolve({ sonde: 5, maraudeur: 0 }, seed: 7)
    expect(r1.exploration_points).to eq(r2.exploration_points)
    expect(r1.resources).to           eq(r2.resources)
  end

  # ── Module-level constants (Correction 5) ─────────────────────────────────

  it "Explorations module declares EXPLORATION_LEVEL_BASE = 400" do
    expect(Explorations::EXPLORATION_LEVEL_BASE).to eq(400)
  end

  it "Explorations module declares EXPLORATION_LEVEL_FACTOR = 1.7" do
    expect(Explorations::EXPLORATION_LEVEL_FACTOR).to eq(1.7)
  end

  it "Explorations module declares MAX_SIMULTANEOUS_EXPLORATIONS = 5" do
    expect(Explorations::MAX_SIMULTANEOUS_EXPLORATIONS).to eq(5)
  end
end
