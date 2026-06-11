module Combats
  class Resolver
    # All tunable constants in one place — never hard-coded in logic (combat_reference §12, §5, §7, §9).
    CONFIG = {
      sigma:             0.25,   # swing global std-dev, Normal(1, sigma) per camp per round (§5)
      jitter_min:        0.85,   # per-shot jitter range lower bound (§5)
      jitter_max:        1.15,   # per-shot jitter range upper bound (§5)
      ej2:               1.0075, # E[jitter²] for U[0.85, 1.15] — used in variance formula (§12)
      round_cap:         18,     # statu quo cap: attacker retreats if reached (§7)
      retreat_threshold: 0.55,   # cumulative attacker loss fraction that triggers retreat (§7)
      tech_rate:         0.04,   # r in stat_eff = stat_base × (1 + r × tech_level) (§9)
      farewell_k:        8.0,    # divisor in farewell multiplier: clamp(0.5 − Δ/k, 0, 1.5) (§7)
    }.freeze

    Result = Struct.new(
      :outcome,          # :attacker_wins | :defender_holds | :attacker_retreat
      :rounds_log,       # [{round:, attacker: {type=>n}, defender: {type=>n}}]
      :losses,           # {attacker: {type=>n}, defender: {type=>n}}
      :xp,               # {attacker: Integer, defender: Integer}
      :pillage_capacity, # Integer (transport capacity of surviving attacker; 0 unless attacker_wins)
      keyword_init: true
    )

    # attacker_force, defender_force: Hash { unit_type_symbol_or_string => Integer }
    # context keys: assault_kind (:portal|:ship), iris_active (bool), iris_bonus (float),
    #               attacker_tech ({armement:, blindage_tactique:, guerre_electronique:} => level),
    #               defender_tech (same), seed (Integer for reproducibility)
    def initialize(attacker_force, defender_force, context = {})
      @attacker_force = normalize_force(attacker_force)
      @defender_force = normalize_force(defender_force)
      @context        = context
      @rng            = Random.new(context[:seed] || Random.new_seed)
    end

    def call
      att_eff = compute_eff_stats(@attacker_force, attacker_tech, 0.0)
      def_eff = compute_eff_stats(@defender_force, defender_tech, iris_def_bonus)

      att = @attacker_force.dup
      dfn = @defender_force.dup

      initial_att       = @attacker_force.dup
      initial_dfn       = @defender_force.dup
      initial_att_total = initial_att.values.sum.to_f

      rounds_log = []
      round      = 0
      retreated  = false

      while alive?(att) && alive?(dfn)
        break if round >= CONFIG[:round_cap]

        round += 1
        att, dfn = resolve_round(att, dfn, att_eff, def_eff)
        rounds_log << { round: round, attacker: att.dup, defender: dfn.dup }

        next unless alive?(dfn) && alive?(att)

        cumulative_loss = (initial_att_total - att.values.sum) / initial_att_total
        if cumulative_loss > CONFIG[:retreat_threshold]
          att       = farewell_volley(dfn, att, def_eff, att_eff)
          retreated = true
          rounds_log << { round: round, event: :retreat, attacker: att.dup, defender: dfn.dup }
          break
        end
      end

      # Statu quo cap: attacker still alive after round_cap rounds → forced retreat with farewell.
      if !retreated && alive?(att) && alive?(dfn)
        att       = farewell_volley(dfn, att, def_eff, att_eff)
        retreated = true
        rounds_log << { round: round, event: :cap_retreat, attacker: att.dup, defender: dfn.dup }
      end

      outcome = determine_outcome(retreated, att, dfn)
      losses  = compute_losses(initial_att, initial_dfn, att, dfn)
      xp      = compute_xp(losses, initial_att, initial_dfn, outcome)
      pillage = pillage_capacity(att, outcome)

      Result.new(outcome: outcome, rounds_log: rounds_log, losses: losses,
                 xp: xp, pillage_capacity: pillage)
    end

    private

    # ── Force helpers ──────────────────────────────────────────────────────────

    def normalize_force(force)
      force.transform_keys(&:to_sym)
           .transform_values(&:to_i)
           .reject { |_, v| v <= 0 }
    end

    def alive?(force)
      force.any? { |_, c| c > 0 }
    end

    # ── Context helpers ────────────────────────────────────────────────────────

    def attacker_tech
      (@context[:attacker_tech] || {}).transform_keys(&:to_sym)
    end

    def defender_tech
      (@context[:defender_tech] || {}).transform_keys(&:to_sym)
    end

    def iris_def_bonus
      return 0.0 unless @context[:assault_kind] == :portal && @context[:iris_active]

      (@context[:iris_bonus] || 0.0).to_f
    end

    # ── Effective stats ────────────────────────────────────────────────────────

    # Applies stat_eff = stat_base × (1 + r × tech_level) for each stat (§9).
    # def_bonus (iris) is an additional DEF multiplier (e.g. 0.15 = +15%).
    def compute_eff_stats(force, tech, def_bonus)
      r = CONFIG[:tech_rate]
      force.keys.each_with_object({}) do |type, h|
        cfg   = Units::REGISTRY.fetch(type) { raise ArgumentError, "Unknown unit type: #{type}" }
        stats = cfg[:stats]

        atk_mult = 1.0 + r * tech.fetch(:armement,            0).to_i
        def_mult = 1.0 + r * tech.fetch(:blindage_tactique,   0).to_i
        int_mult = 1.0 + r * tech.fetch(:guerre_electronique,  0).to_i

        h[type] = {
          atk:    stats[:atk]  * atk_mult,
          def:    stats[:def]  * def_mult * (1.0 + def_bonus),
          int:    stats[:int]  * int_mult,
          combat: cfg[:combat],
          mule:   type == :mule,
        }
      end
    end

    # ── Initiative ─────────────────────────────────────────────────────────────

    # Mean INT weighted by ATQ, over combat? units only (§6).
    # Non-combat units (scientifique, sonde, spectre, mule) are excluded even if atk > 0.
    def army_int(force, eff)
      num = den = 0.0
      force.each do |type, count|
        next unless count > 0 && eff[type][:combat]

        num += eff[type][:int] * eff[type][:atk] * count
        den += eff[type][:atk] * count
      end
      den > 0 ? num / den : 0.0
    end

    # ── Round resolution ───────────────────────────────────────────────────────

    def resolve_round(att, dfn, att_eff, def_eff)
      ia  = army_int(att, att_eff)
      idf = army_int(dfn, def_eff)
      sA  = sample_swing
      sD  = sample_swing

      if (ia - idf).abs < 1e-9
        # Simultaneous: fire on copies of the original forces (§6)
        new_dfn = fire(att, dfn, att_eff, def_eff, sA)
        new_att = fire(dfn, att, def_eff, att_eff, sD)
        [new_att, new_dfn]
      elsif ia > idf
        dfn = fire(att, dfn, att_eff, def_eff, sA)
        att = fire(dfn, att, def_eff, att_eff, sD) if alive?(dfn)
        [att, dfn]
      else
        att = fire(dfn, att, def_eff, att_eff, sD)
        dfn = fire(att, dfn, att_eff, def_eff, sA) if alive?(att)
        [att, dfn]
      end
    end

    # ── Closed-form fire model ─────────────────────────────────────────────────

    # Aggregate ATQ concentrated proportionally on n eligible targets (§3, §4, §12).
    # swing: per-round global multiplier for this volley, sampled Normal(1, sigma).
    # mult:  farewell-volley scalar (1.0 in normal rounds).
    #
    # Derivation: each target unit receives ~N(sum1/n, sqrt(sum2·EJ2/n)) total damage scaled by swing.
    # It dies if damage >= def, i.e. if swing·X >= def where X ~ N(mean_base, sd_base).
    # p_kill = P(X >= def/swing) = 1 − Φ((def/swing − mean) / sd).
    def fire(shooters, targets, shooter_eff, target_eff, swing, mult = 1.0)
      sum1 = sum2 = 0.0
      shooters.each do |type, count|
        next unless count > 0 && shooter_eff[type][:combat] && shooter_eff[type][:atk] > 0

        sum1 += count * shooter_eff[type][:atk]
        sum2 += count * shooter_eff[type][:atk]**2
      end
      return targets.dup if sum1.zero?

      elig = eligible_targets(targets, target_eff)
      n    = elig.sum { |t| targets[t].to_i }
      return targets.dup if n.zero?

      mean       = (sum1 / n) * mult
      sd         = Math.sqrt(sum2 * CONFIG[:ej2] / n) * mult
      safe_swing = [swing, 0.05].max

      result = targets.dup
      elig.each do |type|
        threshold = target_eff[type][:def] / safe_swing
        p_kill    = 1.0 - normal_cdf((threshold - mean) / sd)
        killed    = (result[type] * p_kill).round
        result[type] = [0, result[type] - killed].max
      end
      result
    end

    # ── Farewell volley ────────────────────────────────────────────────────────

    # Fired by the defender when attacker retreats (§7).
    # Multiplier = clamp(0.5 − Δ/k, 0, 1.5) where Δ = INT_attacker − INT_defender.
    # High attacker INT → clean retreat; high defender INT → heavy losses.
    def farewell_volley(shooters, targets, shooter_eff, target_eff)
      ia    = army_int(targets,  target_eff)
      idf   = army_int(shooters, shooter_eff)
      delta = ia - idf
      mult  = [[0.5 - delta / CONFIG[:farewell_k], 0.0].max, 1.5].min
      swing = sample_swing
      fire(shooters, targets, shooter_eff, target_eff, swing, mult)
    end

    # ── Target priority ────────────────────────────────────────────────────────

    # Returns the first non-empty priority tier (§4, §9):
    # 1. combat? units, 2. non-combat non-mule units, 3. mule units.
    def eligible_targets(force, eff)
      tiers = [
        force.keys.select { |t| force[t].to_i > 0 && eff[t][:combat] },
        force.keys.select { |t| force[t].to_i > 0 && !eff[t][:combat] && !eff[t][:mule] },
        force.keys.select { |t| force[t].to_i > 0 &&  eff[t][:mule] },
      ]
      tiers.find(&:any?) || []
    end

    # ── Outcome & reporting ────────────────────────────────────────────────────

    def determine_outcome(retreated, att, dfn)
      return :attacker_retreat if retreated
      return :attacker_wins    if alive?(att) && !alive?(dfn)

      :defender_holds
    end

    def compute_losses(initial_att, initial_dfn, att, dfn)
      att_losses = initial_att.each_with_object({}) do |(type, start), h|
        lost = start - att.fetch(type, 0)
        h[type] = lost if lost > 0
      end
      def_losses = initial_dfn.each_with_object({}) do |(type, start), h|
        lost = start - dfn.fetch(type, 0)
        h[type] = lost if lost > 0
      end
      { attacker: att_losses, defender: def_losses }
    end

    # XP = Σ (resource_cost(type) × kills).
    # Multiplier applies only if the camp won with zero own losses (§11).
    def compute_xp(losses, initial_att, initial_dfn, outcome)
      att_base = losses[:defender].sum { |type, n| unit_xp_value(type) * n }
      def_base = losses[:attacker].sum { |type, n| unit_xp_value(type) * n }

      { attacker: att_base * xp_multiplier(:attacker, outcome, losses, initial_att, initial_dfn),
        defender: def_base * xp_multiplier(:defender, outcome, losses, initial_att, initial_dfn) }
    end

    def unit_xp_value(type)
      cost = Units.cost_for(type)
      cost[:metal].to_i + cost[:food].to_i + cost[:thorium].to_i
    end

    # XP bonus table from §11 — keyed on att/def force ratio.
    # Only applies to the winning side if they suffered zero losses.
    def xp_multiplier(side, outcome, losses, initial_att, initial_dfn)
      won = (side == :attacker && outcome == :attacker_wins) ||
            (side == :defender && outcome == :defender_holds)
      return 1 unless won && losses[side].empty?

      att_total = initial_att.values.sum.to_f
      def_total = initial_dfn.values.sum.to_f
      ratio     = att_total / def_total

      if    ratio > 20.0 then 1
      elsif ratio > 15.0 then 3
      elsif ratio > 10.0 then 5
      elsif ratio >  5.0 then 10
      else                    15
      end
    end

    def pillage_capacity(att, outcome)
      return 0 unless outcome == :attacker_wins

      att.sum { |type, count| Units::REGISTRY[type][:stats][:transport].to_i * count }
    end

    # ── RNG ────────────────────────────────────────────────────────────────────

    # Box-Muller transform producing Normal(1, sigma), bounded away from zero (§5).
    def sample_swing
      u1 = @rng.rand
      u2 = @rng.rand
      u1 = @rng.rand while u1 <= 0.0
      z = Math.sqrt(-2.0 * Math.log(u1)) * Math.cos(2.0 * Math::PI * u2)
      [1.0 + CONFIG[:sigma] * z, 0.05].max
    end

    def normal_cdf(x)
      0.5 * (1.0 + Math.erf(x / Math.sqrt(2.0)))
    end
  end
end
