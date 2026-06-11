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

  # ── XP base ───────────────────────────────────────────────────────────────

  it "XP is 0 for mule-only team (mule exploration = nil)" do
    100.times do |seed|
      r = resolve({ mule: 10 }, seed: seed)
      expect(r.exploration_points).to eq(0)
    end
  end

  it "XP scales with scientifique count (§7: main XP driver)" do
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

  # ── Resources ─────────────────────────────────────────────────────────────

  it "resources are always non-negative" do
    20.times do |seed|
      r = resolve({ sonde: 5, maraudeur: 5 }, seed: seed)
      expect(r.resources[:metal]).to   be >= 0
      expect(r.resources[:food]).to    be >= 0
      expect(r.resources[:thorium]).to be >= 0
    end
  end

  it "spectre-only team (transport 0) always gets zero resources (§7: capped by transport)" do
    20.times do |seed|
      r = resolve({ spectre: 10 }, seed: seed)
      expect(r.resources[:metal]).to   eq(0)
      expect(r.resources[:food]).to    eq(0)
      expect(r.resources[:thorium]).to eq(0)
    end
  end

  it "resources per type never exceed team transport capacity (§7)" do
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
    # Use 200 units so 2% frac × 200 = 4 losses (rounding artefacts don't dominate)
    no_loss_count = 200.times.count { |s| resolve({ sonde: 200 }, seed: s).losses.empty? }
    # expect roughly 55% no-loss; 45..65% is safe tolerance
    expect(no_loss_count).to be_between(90, 130)
  end

  it "critical loss tier (~2%) can wipe most of the team" do
    # Use sonde-only team (no escort) so escort_mult = 1.0 and critical frac [0.6-1.0] is fully applied
    results = 500.times.map { |s| resolve({ sonde: 100 }, seed: s) }
    # Critical tier: 60-100% of 100 = 60-100 losses; all critical events satisfy >= 60
    wipeout = results.select { |r| r.losses.values.sum >= 60 }
    expect(wipeout.size).to be_between(2, 25)
  end

  it "escort reduces average loss fraction (§7: combat units reduce loss fraction)" do
    seeds = 100
    force_base     = { sonde: 10 }
    force_escorted = { sonde: 10, sentinelle: 30 }

    # Compare fraction of losses, not absolute count (teams have different sizes)
    avg_frac_base     = seeds.times.sum { |s| resolve(force_base,     seed: s).losses.values.sum }.to_f / (seeds * 10)
    avg_frac_escorted = seeds.times.sum { |s| resolve(force_escorted, seed: s).losses.values.sum }.to_f / (seeds * 40)

    expect(avg_frac_escorted).to be < avg_frac_base
  end

  it "recon units (sonde/spectre) suffer proportionally fewer losses than combat units (§7)" do
    results = 100.times.map { |s| resolve({ maraudeur: 50, sonde: 50 }, seed: s) }
    results_with_losses = results.reject { |r| r.losses.empty? }
    next if results_with_losses.empty?

    ratio_recon  = results_with_losses.sum { |r| r.losses.fetch(:sonde, 0).to_f / 50 }
    ratio_combat = results_with_losses.sum { |r| r.losses.fetch(:maraudeur, 0).to_f / 50 }
    expect(ratio_recon).to be < ratio_combat
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
end
