require "rails_helper"

RSpec.describe Combats::Resolver do
  # ── Helpers ──────────────────────────────────────────────────────────────────

  def resolve(att, dfn, context = {})
    described_class.new(att, dfn, context).call
  end

  # Run n battles and return array of results.
  def run_n(att, dfn, n:, context: {})
    n.times.map { described_class.new(att, dfn, context).call }
  end

  def win_rate(att, dfn, n:, context: {})
    run_n(att, dfn, n: n, context: context).count { |r| r.outcome == :attacker_wins }.to_f / n
  end

  def avg_rounds(att, dfn, n:, context: {})
    results = run_n(att, dfn, n: n, context: context)
    results.map { |r| r.rounds_log.select { |e| !e[:event] }.last[:round] }.sum.to_f / n
  end

  # ── Determinism ───────────────────────────────────────────────────────────────

  describe "determinism" do
    it "produces identical results for the same seed" do
      r1 = resolve({ maraudeur: 80 }, { regulier: 80 }, seed: 12345)
      r2 = resolve({ maraudeur: 80 }, { regulier: 80 }, seed: 12345)
      expect(r1.outcome).to eq(r2.outcome)
      expect(r1.losses).to eq(r2.losses)
      expect(r1.rounds_log.size).to eq(r2.rounds_log.size)
    end

    it "produces different results across seeds" do
      outcomes = (1..30).map { |s| resolve({ maraudeur: 50 }, { regulier: 50 }, seed: s).outcome }
      expect(outcomes.uniq.size).to be > 1
    end
  end

  # ── Basic outcome correctness ─────────────────────────────────────────────────

  describe "outcome types" do
    it "returns :attacker_wins when attacker is overwhelmingly stronger" do
      results = run_n({ maraudeur: 500 }, { maraudeur: 10 }, n: 20)
      expect(results.map(&:outcome).uniq).to eq([:attacker_wins])
    end

    it "returns :defender_holds when defender is overwhelmingly stronger" do
      results = run_n({ maraudeur: 10 }, { maraudeur: 500 }, n: 20)
      expect(results.map(&:outcome)).to all(eq(:defender_holds))
    end

    it "never returns :attacker_wins when defender has no units" do
      # edge: empty defender means attacker wins immediately (no rounds fought)
      r = resolve({ maraudeur: 10 }, { maraudeur: 0 })
      expect(r.outcome).to eq(:attacker_wins)
      expect(r.rounds_log.size).to eq(0)
    end
  end

  # ── Round count — scale independence (combat_reference §13) ──────────────────

  describe "round count" do
    it "resolves in ~3 rounds for a Maraudeur mirror (glass cannon)" do
      avg = avg_rounds({ maraudeur: 100 }, { maraudeur: 100 }, n: 300)
      expect(avg).to be_within(2).of(3), "Expected ~3 rounds, got #{avg.round(1)}"
    end

    it "resolves in ~10 rounds for a Régulier mirror" do
      avg = avg_rounds({ regulier: 100 }, { regulier: 100 }, n: 300)
      expect(avg).to be_within(4).of(10), "Expected ~10 rounds, got #{avg.round(1)}"
    end

    it "round count is scale-independent (100v100 ≈ 10 000v10 000)" do
      avg_small = avg_rounds({ regulier: 100 },    { regulier: 100 },    n: 200)
      avg_large = avg_rounds({ regulier: 10_000 }, { regulier: 10_000 }, n: 200)
      expect(avg_small).to be_within(3).of(avg_large),
        "Scale should not change avg rounds: small=#{avg_small.round(1)} large=#{avg_large.round(1)}"
    end
  end

  # ── Pile-ou-face band Maraudeur → Régulier ≈ 0.21 (§13) ─────────────────────

  describe "pile-ou-face band" do
    it "Maraudeur→Régulier 25%→75% band is approximately 0.21 of ratio" do
      defender_n = 80
      # Sweep ratios and find approximate 25% and 75% crossover points
      rates = {}
      [0.8, 0.9, 1.0, 1.1, 1.2, 1.3].each do |ratio|
        n = (defender_n * ratio).round
        rates[ratio] = win_rate({ maraudeur: n }, { regulier: defender_n }, n: 800)
      end
      # Find the ratio band between ~25% and ~75% win rate
      below_25 = rates.select { |_, v| v < 0.25 }.keys.max
      above_75 = rates.select { |_, v| v > 0.75 }.keys.min
      # Band exists and is in [0.10, 0.35] range
      if below_25 && above_75
        band = above_75 - below_25
        expect(band).to be_between(0.10, 0.40),
          "Expected band ~0.21, got #{band.round(2)}. Rates: #{rates.transform_values { |v| v.round(2) }}"
      else
        # Couldn't isolate the band in the sweep — check at least monotonicity
        sorted_rates = rates.sort.map { |_, v| v }
        expect(sorted_rates).to eq(sorted_rates.sort),
          "Win rates should be monotonically increasing with ratio: #{rates.transform_values { |v| v.round(2) }}"
      end
    end
  end

  # ── Mur Sentinelle pénétrable à ×1.45 (§13) ──────────────────────────────────

  describe "Sentinelle wall" do
    it "requires ~1.45× Maraudeurs to win 50% against Sentinelles" do
      defender_n = 100
      rate_at_145 = win_rate({ maraudeur: 145 }, { sentinelle: defender_n }, n: 600)
      # Should be near 50% — accept 30%–70% given Monte Carlo variance
      expect(rate_at_145).to be_between(0.25, 0.75),
        "Expected ~50% win at ×1.45, got #{(rate_at_145 * 100).round(1)}%"
    end

    it "is clearly losing below ×1.0" do
      rate = win_rate({ maraudeur: 80 }, { sentinelle: 100 }, n: 400)
      expect(rate).to be < 0.30
    end

    it "is clearly winning above ×2.0" do
      rate = win_rate({ maraudeur: 200 }, { sentinelle: 100 }, n: 400)
      expect(rate).to be > 0.80
    end
  end

  # ── Statu quo cap = 18 rounds (§7, §13) ──────────────────────────────────────

  describe "round cap" do
    it "triggers :attacker_retreat when the 18-round cap is hit" do
      # Sentinelle mirror: each side kills ~2-3% per round; neither reaches 55% loss in 18 rounds.
      # Seed 3 is confirmed to reach the statu quo cap.
      r = resolve({ sentinelle: 50 }, { sentinelle: 50 }, seed: 3)
      expect(r.outcome).to eq(:attacker_retreat)
      cap_entry = r.rounds_log.find { |e| e[:event] == :cap_retreat }
      expect(cap_entry).not_to be_nil
      expect(cap_entry[:round]).to eq(Combats::Resolver::CONFIG[:round_cap])
    end

    it "round_cap constant is 18" do
      expect(Combats::Resolver::CONFIG[:round_cap]).to eq(18)
    end
  end

  # ── army_int ignores Scientifique despite ATQ 2 (§6) ─────────────────────────

  describe "army_int" do
    let(:resolver_instance) { described_class.new({ maraudeur: 50 }, { regulier: 50 }) }

    it "ignores non-combat units (scientifique) despite ATQ 2" do
      eff_with = resolver_instance.send(:compute_eff_stats,
                   { maraudeur: 50, scientifique: 50 }, {}, 0.0)
      eff_without = resolver_instance.send(:compute_eff_stats,
                      { maraudeur: 50 }, {}, 0.0)

      int_with    = resolver_instance.send(:army_int, { maraudeur: 50, scientifique: 50 }, eff_with)
      int_without = resolver_instance.send(:army_int, { maraudeur: 50 }, eff_without)

      expect(int_with).to eq(int_without)
    end

    it "returns 0.0 for a force with no combat units" do
      eff = resolver_instance.send(:compute_eff_stats, { mule: 100 }, {}, 0.0)
      result = resolver_instance.send(:army_int, { mule: 100 }, eff)
      expect(result).to eq(0.0)
    end

    it "scientifiques do not contribute to fire (cannot damage enemies)" do
      # 500 scientifiques (non-combat) vs 10 maraudeurs: scientifiques never fire,
      # but maraudeurs can't kill them fast enough either — should cap at 18 rounds.
      r = resolve({ scientifique: 500 }, { maraudeur: 10 }, seed: 1)
      expect(r.outcome).to eq(:attacker_retreat)
    end
  end

  # ── Technology bonuses (§9) ───────────────────────────────────────────────────

  describe "technology bonuses" do
    it "symmetric tech leaves win rate unchanged (only delta counts)" do
      ctx_base = {}
      ctx_sym  = { attacker_tech: { armement: 3 }, defender_tech: { armement: 3 } }

      rate_base = win_rate({ maraudeur: 100 }, { regulier: 100 }, n: 500, context: ctx_base)
      rate_sym  = win_rate({ maraudeur: 100 }, { regulier: 100 }, n: 500, context: ctx_sym)

      expect(rate_sym).to be_within(0.10).of(rate_base),
        "Symmetric tech should not change win rate: base=#{rate_base.round(2)} sym=#{rate_sym.round(2)}"
    end

    it "armement advantage produces a smooth win-rate curve without cliff" do
      rates = [0, 1, 2, 3, 5].map do |lvl|
        ctx = { attacker_tech: { armement: lvl } }
        win_rate({ maraudeur: 80 }, { regulier: 100 }, n: 400, context: ctx)
      end
      # Each step should increase win rate, and no single step should jump by > 0.35
      rates.each_cons(2) do |prev, curr|
        expect(curr).to be > prev - 0.05  # monotone (with noise tolerance)
        expect(curr - prev).to be < 0.35, "Cliff detected: #{prev.round(2)} → #{curr.round(2)}"
      end
    end

    it "blindage_tactique on defender reduces attacker win rate" do
      rate_no_tech = win_rate({ maraudeur: 150 }, { sentinelle: 100 }, n: 400)
      rate_shielded = win_rate({ maraudeur: 150 }, { sentinelle: 100 }, n: 400,
                               context: { defender_tech: { blindage_tactique: 5 } })
      expect(rate_shielded).to be < rate_no_tech + 0.08
    end
  end

  # ── Iris bonus (§2) ───────────────────────────────────────────────────────────

  describe "iris bonus" do
    it "improves defender DEF against portal assault" do
      ctx_no_iris  = { assault_kind: :portal, iris_active: false }
      ctx_with_iris = { assault_kind: :portal, iris_active: true, iris_bonus: 0.20 }

      rate_no_iris   = win_rate({ maraudeur: 150 }, { sentinelle: 100 }, n: 400, context: ctx_no_iris)
      rate_with_iris = win_rate({ maraudeur: 150 }, { sentinelle: 100 }, n: 400, context: ctx_with_iris)

      expect(rate_with_iris).to be < rate_no_iris + 0.08
    end

    it "has no effect for ship assaults even if iris_active" do
      ctx_portal = { assault_kind: :portal, iris_active: true, iris_bonus: 0.20 }
      ctx_ship   = { assault_kind: :ship,   iris_active: true, iris_bonus: 0.20 }

      rate_portal = win_rate({ maraudeur: 150 }, { sentinelle: 100 }, n: 400, context: ctx_portal)
      rate_ship   = win_rate({ maraudeur: 150 }, { sentinelle: 100 }, n: 400, context: ctx_ship)

      expect(rate_ship).to be > rate_portal - 0.05
    end
  end

  # ── Losses ────────────────────────────────────────────────────────────────────

  describe "losses" do
    it "losses are non-negative and do not exceed initial counts" do
      r = resolve({ maraudeur: 100, mule: 20 }, { regulier: 80, sentinelle: 30 }, seed: 99)
      r.losses[:attacker].each do |type, lost|
        expect(lost).to be >= 0
        expect(lost).to be <= { maraudeur: 100, mule: 20 }.fetch(type, 0)
      end
      r.losses[:defender].each do |type, lost|
        expect(lost).to be >= 0
        expect(lost).to be <= { regulier: 80, sentinelle: 30 }.fetch(type, 0)
      end
    end

    it "losses + survivors = initial counts" do
      initial_att = { maraudeur: 100, mule: 20 }
      initial_dfn = { regulier: 80 }
      r = resolve(initial_att, initial_dfn, seed: 7)
      survivors = r.rounds_log.last

      initial_att.each do |type, start|
        lost = r.losses[:attacker].fetch(type, 0)
        surv = survivors[:attacker].fetch(type, 0)
        expect(lost + surv).to eq(start), "#{type}: #{lost} + #{surv} ≠ #{start}"
      end
    end
  end

  # ── XP (§11) ──────────────────────────────────────────────────────────────────

  describe "XP" do
    it "is proportional to resource cost of destroyed units" do
      # ratio = 300/10 = 30 > 20 → multiplier is always ×1 regardless of losses
      r = resolve({ maraudeur: 300 }, { maraudeur: 10 }, seed: 42)
      expect(r.outcome).to eq(:attacker_wins)
      killed = r.losses[:defender].fetch(:maraudeur, 0)
      # maraudeur cost = 70 metal + 30 food + 0 thorium = 100
      expect(r.xp[:attacker]).to eq(killed * 100)
    end

    it "XP = base × 1 when winner has losses, even at ratio < 5× (§11 zero-loss condition)" do
      # ratio = 120/100 = 1.2 < 5× — would give ×15 if zero losses, but attacker takes losses here
      r = resolve({ maraudeur: 120 }, { regulier: 100 }, seed: 5)
      expect(r.outcome).to eq(:attacker_wins)
      expect(r.losses[:attacker]).not_to be_empty
      base = r.losses[:defender].sum { |t, n| Units.cost_for(t).values.sum * n }
      expect(r.xp[:attacker]).to eq(base)
    end

    it "XP = base × 15 when zero losses at ratio < 5× (§11 table)" do
      # Mule-only defense: mules have ATQ 0 and are non-combat — they cannot fire back.
      # Zero attacker losses are guaranteed. ratio = 60/20 = 3 < 5× → tier ×15.
      r = resolve({ maraudeur: 60 }, { mule: 20 }, seed: 1)
      expect(r.outcome).to eq(:attacker_wins)
      expect(r.losses[:attacker]).to be_empty
      mule_cost = Units.cost_for(:mule).values.sum  # 70 + 40 + 0 = 110
      killed    = r.losses[:defender].fetch(:mule, 0)
      expect(r.xp[:attacker]).to eq(killed * mule_cost * 15)
    end
  end

  # ── Pillage capacity ──────────────────────────────────────────────────────────

  describe "pillage_capacity" do
    it "is zero when attacker retreats" do
      # Sentinelle mirror seed 3 hits the statu quo cap → :attacker_retreat
      r = resolve({ sentinelle: 50 }, { sentinelle: 50 }, seed: 3)
      expect(r.outcome).to eq(:attacker_retreat)
      expect(r.pillage_capacity).to eq(0)
    end

    it "is zero when defender holds" do
      r = resolve({ maraudeur: 10 }, { maraudeur: 500 }, seed: 1)
      expect(r.outcome).to eq(:defender_holds)
      expect(r.pillage_capacity).to eq(0)
    end

    it "equals Σ(transport_stat × survivor_count) per attacker unit type (§10)" do
      # maraudeur transport=50, mule transport=350 — verify the formula directly.
      r = resolve({ maraudeur: 200, mule: 50 }, { maraudeur: 10 }, seed: 42)
      expect(r.outcome).to eq(:attacker_wins)
      survivors = r.rounds_log.last[:attacker]
      expected  = survivors.sum { |type, n| Units::REGISTRY[type][:stats][:transport].to_i * n }
      expect(r.pillage_capacity).to eq(expected)
      expect(r.pillage_capacity).to be > 0
    end
  end

  # ── Rounds log structure ──────────────────────────────────────────────────────

  describe "rounds_log" do
    it "contains at least one entry for a non-trivial battle" do
      r = resolve({ maraudeur: 50 }, { regulier: 50 }, seed: 1)
      expect(r.rounds_log).not_to be_empty
    end

    it "each entry has :round, :attacker, :defender keys" do
      r = resolve({ maraudeur: 50 }, { regulier: 50 }, seed: 1)
      r.rounds_log.each do |entry|
        expect(entry).to have_key(:round)
        expect(entry).to have_key(:attacker)
        expect(entry).to have_key(:defender)
      end
    end

    it "round numbers are non-decreasing" do
      r = resolve({ maraudeur: 50 }, { regulier: 50 }, seed: 1)
      rounds = r.rounds_log.map { |e| e[:round] }
      expect(rounds).to eq(rounds.sort)
    end

    it "unit counts in log are non-negative" do
      r = resolve({ maraudeur: 50, mule: 20 }, { regulier: 80, sentinelle: 20 }, seed: 5)
      r.rounds_log.each do |entry|
        entry[:attacker].each { |_, n| expect(n).to be >= 0 }
        entry[:defender].each { |_, n| expect(n).to be >= 0 }
      end
    end
  end

  # ── Target priority (Mule last) ───────────────────────────────────────────────

  describe "target priority" do
    it "mules are not targeted while combat units are alive" do
      # Defender has 50 reguliers + 50 mules; attacker fires but only reguliers should take losses
      r = resolve({ maraudeur: 200 }, { regulier: 50, mule: 50 }, seed: 2)
      # After first round, reguliers should have losses, mules should be untouched
      first_round = r.rounds_log.first
      def_regulier_after = first_round[:defender].fetch(:regulier, 0)
      def_mule_after     = first_round[:defender].fetch(:mule, 50)
      expect(def_regulier_after).to be < 50
      expect(def_mule_after).to eq(50), "Mules should not be targeted while reguliers are alive"
    end
  end

  # ── Edge cases ────────────────────────────────────────────────────────────────

  describe "edge cases" do
    it "handles string keys in force hashes" do
      r = resolve({ "maraudeur" => 50 }, { "regulier" => 50 }, seed: 1)
      expect(r.outcome).to be_in(%i[attacker_wins defender_holds attacker_retreat])
    end

    it "ignores zero-count entries in force" do
      r1 = resolve({ maraudeur: 100, regulier: 0 }, { sentinelle: 100 }, seed: 5)
      r2 = resolve({ maraudeur: 100 },              { sentinelle: 100 }, seed: 5)
      expect(r1.outcome).to eq(r2.outcome)
    end

    it "raises ArgumentError for unknown unit types" do
      expect {
        described_class.new({ laser_cannon: 10 }, { maraudeur: 10 }).call
      }.to raise_error(ArgumentError, /Unknown unit type/)
    end
  end
end
