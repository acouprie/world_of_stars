module Explorations
  class Resolver
    CONFIG = {
      # Resource draw tiers — probabilities and [lo, hi] fraction of team cost (§7).
      resource_tiers: [
        { prob: 0.20, range: [0.00, 0.00] },
        { prob: 0.58, range: [0.01, 0.06] },
        { prob: 0.18, range: [0.06, 0.12] },
        { prob: 0.04, range: [0.12, 0.25] },
      ].freeze,

      # XP draw tiers — probabilities and [lo, hi] multiplier of team XP base (§7).
      xp_tiers: [
        { prob: 0.18, range: [0.0, 0.0] },
        { prob: 0.60, range: [0.3, 0.8] },
        { prob: 0.18, range: [0.8, 1.5] },
        { prob: 0.04, range: [1.5, 3.0] },
      ].freeze,

      # Loss draw tiers — probabilities and [lo, hi] fraction of team count (§7).
      loss_tiers: [
        { prob: 0.55, range: [0.00, 0.00] },
        { prob: 0.33, range: [0.02, 0.10] },
        { prob: 0.10, range: [0.10, 0.30] },
        { prob: 0.02, range: [0.60, 1.00] },
      ].freeze,

      # XP contribution per unit (unit_reference §7: scientifique = main, others = minor_fixed/minor, mule = 0).
      xp_main_per_unit:  10,
      xp_minor_per_unit:  1,

      # Escort: max fractional reduction of losses when entire team is combat (§7).
      escort_reduction_factor: 0.5,

      # Recon units (sonde/spectre) share of loss exposure relative to other unit types (§7: risque réduit).
      recon_loss_weight: 0.3,

      # k_butin: calibration reference E[loot] ≈ k_butin × E[loss cost] (§7). Baked into tier ranges.
      k_butin: 0.8,
    }.freeze

    Result = Struct.new(:exploration_points, :resources, :losses, keyword_init: true)

    def initialize(force, context = {})
      @force   = force.transform_keys(&:to_sym).transform_values(&:to_i).reject { |_, v| v <= 0 }
      @context = context
      @rng     = Random.new(context[:seed] || Random.new_seed)
    end

    def call
      total_count   = @force.values.sum
      team_cost     = compute_team_cost
      transport_cap = compute_transport_cap
      xp_base       = compute_xp_base
      combat_ratio  = compute_combat_ratio

      resources = draw_resources(team_cost, transport_cap)
      xp        = draw_xp(xp_base)
      losses    = draw_losses(total_count, combat_ratio)

      Result.new(exploration_points: xp, resources: resources, losses: losses)
    end

    private

    def compute_team_cost
      @force.sum { |type, count| Units.cost_for(type).values.sum * count }
    end

    def compute_transport_cap
      @force.sum { |type, count| Units::REGISTRY[type][:stats][:transport].to_i * count }
    end

    def compute_xp_base
      @force.sum do |type, count|
        case Units::REGISTRY[type][:stats][:exploration]
        when :main         then CONFIG[:xp_main_per_unit]  * count
        when :minor, :minor_fixed then CONFIG[:xp_minor_per_unit] * count
        else 0
        end
      end
    end

    def compute_combat_ratio
      total = @force.values.sum.to_f
      return 0.0 if total.zero?
      @force.sum { |type, count| Units::REGISTRY[type][:combat] ? count : 0 } / total
    end

    def draw_resources(team_cost, transport_cap)
      frac         = sample_tier(CONFIG[:resource_tiers])
      total_loot   = (frac * team_cost).floor
      per_resource = total_loot / 3
      capped       = [per_resource, transport_cap].min
      { metal: capped, food: capped, thorium: capped }
    end

    def draw_xp(xp_base)
      mult = sample_tier(CONFIG[:xp_tiers])
      (mult * xp_base).round
    end

    def draw_losses(total_count, combat_ratio)
      base_frac = sample_tier(CONFIG[:loss_tiers])
      return {} if base_frac.zero?

      escort_mult    = [1.0 - CONFIG[:escort_reduction_factor] * combat_ratio, 0.0].max
      effective_frac = base_frac * escort_mult
      n_losses       = [[effective_frac * total_count, 0.0].max.round, total_count].min
      return {} if n_losses <= 0

      distribute_losses(n_losses)
    end

    def distribute_losses(n_losses)
      types         = @force.keys
      weighted_pop  = types.each_with_object({}) do |type, h|
        cfg    = Units::REGISTRY[type]
        weight = cfg[:category] == :reconnaissance ? CONFIG[:recon_loss_weight] : 1.0
        h[type] = @force[type] * weight
      end
      total_w = weighted_pop.values.sum
      return {} if total_w.zero?

      result    = {}
      remaining = n_losses

      types.each do |type|
        break if remaining <= 0
        share  = (n_losses * weighted_pop[type] / total_w).round
        actual = [[share, @force[type]].min, remaining].min
        result[type] = actual if actual > 0
        remaining   -= actual
      end

      # Assign any rounding remainder to units with available headroom
      if remaining > 0
        types.each do |type|
          break if remaining <= 0
          headroom = @force[type] - result[type].to_i
          add      = [headroom, remaining].min
          if add > 0
            result[type] = result[type].to_i + add
            remaining   -= add
          end
        end
      end

      result.reject { |_, v| v.to_i <= 0 }
    end

    # Chooses a tier by cumulative probability, then samples uniformly within its range.
    def sample_tier(tiers)
      r          = @rng.rand
      cumulative = 0.0
      tiers.each do |tier|
        cumulative += tier[:prob]
        if r < cumulative
          lo, hi = tier[:range]
          return lo if lo == hi
          return lo + @rng.rand * (hi - lo)
        end
      end
      tiers.last[:range].last
    end
  end
end
