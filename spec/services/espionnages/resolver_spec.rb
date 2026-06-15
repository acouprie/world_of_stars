require "rails_helper"

RSpec.describe Espionnages::Resolver do
  let(:full_state) do
    {
      buildings:    { command_center: 3, training_camp: 2, military_camp: 4 },
      units:        { maraudeur: 500, sentinelle: 200 },
      resources:    { metal: 12_000, food: 8_000, thorium: 3_000 },
      technologies: { armement: 5, blindage_tactique: 3 },
      ships:        { chasseur: 10 },
    }
  end

  def resolve(force, context = {}, defender_state = {})
    described_class.new(force, context, defender_state).call
  end

  # ── Determinism ────────────────────────────────────────────────────────────

  it "produces identical results for the same seed" do
    ctx = { attacker_renseignement: 0, defender_renseignement: 0, seed: 42 }
    r1  = resolve({ spectre: 5 }, ctx, full_state)
    r2  = resolve({ spectre: 5 }, ctx, full_state)
    expect(r1.detected).to          eq(r2.detected)
    expect(r1.attacker_revealed).to eq(r2.attacker_revealed)
    expect(r1.losses).to            eq(r2.losses)
    expect(r1.report).to            eq(r2.report)
  end

  # ── Result structure ───────────────────────────────────────────────────────

  it "returns a Result with detected, attacker_revealed, losses, report" do
    r = resolve({ spectre: 1 }, { seed: 1 })
    expect(r).to respond_to(:detected, :attacker_revealed, :losses, :report)
    expect(r.detected).to be_in([true, false])
    expect(r.attacker_revealed).to be_in([true, false])
    expect(r.losses).to be_a(Hash)
    expect(r.report).to be_a(Hash)
  end

  # ── Detection probability — §6 reference benchmarks ──────────────────────

  it "1 Spectre, equal tech → ~4% detection (§6 repère)" do
    ctx   = { attacker_renseignement: 0, defender_renseignement: 0 }
    count = 500.times.count { |s| resolve({ spectre: 1 }, ctx.merge(seed: s)).detected }
    # Expected: ~4% → 20/500 ±10%
    expect(count.to_f / 500).to be_within(0.05).of(0.04)
  end

  it "5 Spectres, equal tech → ~19% detection (§6 repère)" do
    ctx   = { attacker_renseignement: 0, defender_renseignement: 0 }
    count = 500.times.count { |s| resolve({ spectre: 5 }, ctx.merge(seed: s)).detected }
    expect(count.to_f / 500).to be_within(0.05).of(0.1875)
  end

  it "5 Sondes, equal tech → ~75% detection (§6 repère)" do
    ctx   = { attacker_renseignement: 0, defender_renseignement: 0 }
    count = 500.times.count { |s| resolve({ sonde: 5 }, ctx.merge(seed: s)).detected }
    expect(count.to_f / 500).to be_within(0.06).of(0.75)
  end

  it "10 Spectres, equal tech → ~38% detection (§6 repère)" do
    ctx   = { attacker_renseignement: 0, defender_renseignement: 0 }
    count = 500.times.count { |s| resolve({ spectre: 10 }, ctx.merge(seed: s)).detected }
    expect(count.to_f / 500).to be_within(0.05).of(0.375)
  end

  it "attacker tech advantage (ta=10, td=0) reduces detection vs equal techs" do
    ctx_eq  = { attacker_renseignement: 0,  defender_renseignement: 0 }
    ctx_adv = { attacker_renseignement: 10, defender_renseignement: 0 }
    det_eq  = 500.times.count { |s| resolve({ spectre: 5 }, ctx_eq.merge(seed: s)).detected }
    det_adv = 500.times.count { |s| resolve({ spectre: 5 }, ctx_adv.merge(seed: s)).detected }
    expect(det_adv).to be < det_eq
  end

  it "defender tech advantage (ta=0, td=10) increases detection vs equal techs" do
    ctx_eq  = { attacker_renseignement: 0, defender_renseignement: 0  }
    ctx_dis = { attacker_renseignement: 0, defender_renseignement: 10 }
    det_eq  = 500.times.count { |s| resolve({ spectre: 5 }, ctx_eq.merge(seed: s)).detected }
    det_dis = 500.times.count { |s| resolve({ spectre: 5 }, ctx_dis.merge(seed: s)).detected }
    expect(det_dis).to be > det_eq
  end

  # ── Losses on detection ───────────────────────────────────────────────────

  it "no losses when not detected" do
    200.times do |s|
      r = resolve({ spectre: 5 }, { attacker_renseignement: 0, defender_renseignement: 0, seed: s })
      expect(r.losses).to eq({}) unless r.detected
    end
  end

  it "5 Spectres equal tech: ~1 unit lost when detected (§6 repère)" do
    ctx      = { attacker_renseignement: 0, defender_renseignement: 0 }
    detected = (0..500).map { |s| resolve({ spectre: 5 }, ctx.merge(seed: s)) }
                       .select(&:detected)
    next if detected.empty?
    avg_losses = detected.sum { |r| r.losses.values.sum }.to_f / detected.size
    expect(avg_losses).to be_within(0.5).of(1.04)
  end

  it "5 Sondes equal tech: ~4 units lost when detected (§6 repère)" do
    ctx      = { attacker_renseignement: 0, defender_renseignement: 0 }
    detected = (0..500).map { |s| resolve({ sonde: 5 }, ctx.merge(seed: s)) }
                       .select(&:detected)
    next if detected.empty?
    avg_losses = detected.sum { |r| r.losses.values.sum }.to_f / detected.size
    expect(avg_losses).to be_within(0.5).of(4.17)
  end

  it "losses are never more than units sent" do
    20.times do |s|
      r = resolve({ spectre: 3, sonde: 2 }, { attacker_renseignement: 0, defender_renseignement: 0, seed: s }, full_state)
      r.losses.each do |type, n|
        force = { spectre: 3, sonde: 2 }
        expect(n).to be <= force[type]
      end
    end
  end

  # ── attacker_revealed ─────────────────────────────────────────────────────

  it "attacker_revealed = true only when detected AND td >= ta (§6)" do
    100.times do |s|
      r = resolve({ spectre: 5 }, { attacker_renseignement: 3, defender_renseignement: 5, seed: s })
      if r.detected
        expect(r.attacker_revealed).to be true  # td(5) >= ta(3)
      else
        expect(r.attacker_revealed).to be false
      end
    end
  end

  it "attacker_revealed = false even when detected if ta > td (§6)" do
    100.times do |s|
      r = resolve({ spectre: 5 }, { attacker_renseignement: 10, defender_renseignement: 0, seed: s })
      expect(r.attacker_revealed).to be false  # ta(10) > td(0) → never revealed
    end
  end

  # ── Depth gating ──────────────────────────────────────────────────────────

  it "n=1: only buildings accessible (§6 depth table)" do
    ctx = { attacker_renseignement: 5, defender_renseignement: 0, seed: 1 }
    r   = resolve({ spectre: 1 }, ctx, full_state)
    expect(r.report.keys).to include(:buildings) if r.report.key?(:buildings)
    expect(r.report.keys).not_to include(:units, :resources, :technologies, :ships)
  end

  it "n=3: buildings, units, resources accessible; technologies not (§6 depth table)" do
    ctx = { attacker_renseignement: 5, defender_renseignement: 0, seed: 1 }
    r   = resolve({ spectre: 3 }, ctx, full_state)
    expect(r.report.keys).to include(:buildings, :units, :resources)
    expect(r.report.keys).not_to include(:technologies, :ships)
  end

  it "n=4, ta < td: technologies blocked despite depth 4 (§6 condition ta >= td)" do
    ctx = { attacker_renseignement: 0, defender_renseignement: 5, seed: 1 }
    r   = resolve({ spectre: 4 }, ctx, full_state)
    expect(r.report.keys).not_to include(:technologies)
  end

  it "n=4, ta >= td: technologies accessible (§6 depth 4 condition)" do
    ctx = { attacker_renseignement: 5, defender_renseignement: 0, seed: 1 }
    r   = resolve({ spectre: 4 }, ctx, full_state)
    expect(r.report.keys).to include(:technologies)
  end

  it "n=5, no spectre: ships not accessible (§6 depth 5 requires spectre)" do
    ctx = { attacker_renseignement: 5, defender_renseignement: 0, seed: 1 }
    r   = resolve({ sonde: 5 }, ctx, full_state)
    expect(r.report.keys).not_to include(:ships)
  end

  it "n=5, spectre present: ships accessible (§6 depth 5)" do
    ctx = { attacker_renseignement: 5, defender_renseignement: 0, seed: 1 }
    r   = resolve({ spectre: 5 }, ctx, full_state)
    expect(r.report.keys).to include(:ships)
  end

  # ── Completeness ──────────────────────────────────────────────────────────

  it "5 Spectres equal tech: buildings completeness ~70% (§6 repère)" do
    ctx  = { attacker_renseignement: 0, defender_renseignement: 0 }
    total_fields = full_state[:buildings].size
    revealed = 500.times.sum { |s|
      resolve({ spectre: 5 }, ctx.merge(seed: s), full_state).report.fetch(:buildings, {}).size
    }.to_f
    avg_completeness = revealed / (500 * total_fields)
    expect(avg_completeness).to be_within(0.08).of(0.70)
  end

  it "5 Spectres equal tech: units completeness ~60% (§6 repère)" do
    ctx  = { attacker_renseignement: 0, defender_renseignement: 0 }
    total_fields = full_state[:units].size
    revealed = 500.times.sum { |s|
      resolve({ spectre: 5 }, ctx.merge(seed: s), full_state).report.fetch(:units, {}).size
    }.to_f
    avg_completeness = revealed / (500 * total_fields)
    expect(avg_completeness).to be_within(0.08).of(0.60)
  end

  it "1 Spectre equal tech: buildings completeness ~14% (§6 repère)" do
    ctx  = { attacker_renseignement: 0, defender_renseignement: 0 }
    total_fields = full_state[:buildings].size
    revealed = 500.times.sum { |s|
      resolve({ spectre: 1 }, ctx.merge(seed: s), full_state).report.fetch(:buildings, {}).size
    }.to_f
    avg_completeness = revealed / (500 * total_fields)
    expect(avg_completeness).to be_within(0.05).of(0.14)
  end

  it "empty defender_state returns empty report" do
    ctx = { attacker_renseignement: 0, defender_renseignement: 0, seed: 1 }
    r   = resolve({ spectre: 5 }, ctx, {})
    expect(r.report.values.all?(&:empty?)).to be true
  end

  it "report values are numeric (noised copies of defender_state values)" do
    ctx = { attacker_renseignement: 10, defender_renseignement: 0, seed: 1 }
    r   = resolve({ spectre: 10 }, ctx, full_state)
    r.report.each do |_cat, data|
      data.each_value { |v| expect(v).to be_a(Numeric) }
    end
  end
end
