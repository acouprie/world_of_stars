module Explorations
  # Player exploration levels: threshold(n) = EXPLORATION_LEVEL_BASE * EXPLORATION_LEVEL_FACTOR**(n-1)
  EXPLORATION_LEVEL_BASE        = 400
  EXPLORATION_LEVEL_FACTOR      = 1.7
  EXPLORATION_GAIN_PER_LEVEL    = 1.0292
  MAX_SIMULTANEOUS_EXPLORATIONS = 5

  class Resolver
    # Risk weights shared by losses and loot base (exploration_magnitude_v1 §2).
    # Keyed by unit category; reconnaissance units survive better, mules are easy targets.
    RISK_WEIGHTS = {
      reconnaissance: 0.6,
      exploration:    1.0,
      combat:         1.1,
      transport:      1.2
    }.freeze

    # XP contribution per unit (exploration_magnitude_v1 §1, validated with ×1.7 level curve).
    XP_BASES = {
      scientifique: 60, sonde: 25, spectre: 25,
      maraudeur: 10,    regulier: 10, sentinelle: 10, mule: 0
    }.freeze

    CONFIG = {
      # Resource draw tiers (§7 GDD, conserved): probabilities and [lo, hi] fraction of loot base.
      resource_tiers: [
        { prob: 0.20, range: [0.00, 0.00] },
        { prob: 0.58, range: [0.01, 0.06] },
        { prob: 0.18, range: [0.06, 0.12] },
        { prob: 0.04, range: [0.12, 0.25] }
      ].freeze,

      # XP draw tiers (§7 GDD, conserved): probabilities and [lo, hi] multiplier of XP base.
      xp_tiers: [
        { prob: 0.18, range: [0.0, 0.0] },
        { prob: 0.60, range: [0.3, 0.8] },
        { prob: 0.18, range: [0.8, 1.5] },
        { prob: 0.04, range: [1.5, 3.0] }
      ].freeze,

      # Loss draw tiers (§7 GDD, conserved). Last tier is critical: ignores all modifiers.
      loss_tiers: [
        { prob: 0.55, range: [0.00, 0.00] },
        { prob: 0.33, range: [0.02, 0.10] },
        { prob: 0.10, range: [0.10, 0.30] },
        { prob: 0.02, range: [0.60, 1.00] }
      ].freeze,

      # Escort: per combat-unit share multiplier reducing losses for non-critical tiers (§2).
      escort_reduction:     0.5,

      # Cartographie stellaire: per-level loss reduction, non-critical tiers only (§2).
      carto_loss_reduction: 0.02,

      # Cartographie stellaire: per-level XP bonus. No loot bonus (§2).
      carto_xp_bonus:       0.04
    }.freeze

    Result = Struct.new(:exploration_points, :resources, :losses, keyword_init: true)

    def initialize(force, context = {})
      @force   = force.transform_keys(&:to_sym).transform_values(&:to_i).reject { |_, v| v <= 0 }
      @context = context
      @rng     = Random.new(context[:seed] || Random.new_seed)
    end

    def call
      carto_level   = (@context[:carto_level] || 0).to_i
      transport_cap = compute_transport_cap
      loot_base     = compute_loot_base
      xp_base       = compute_xp_base(carto_level)
      combat_ratio  = compute_combat_ratio

      resources = draw_resources(loot_base, transport_cap)
      xp        = draw_xp(xp_base)
      losses    = draw_losses(combat_ratio, carto_level)

      Result.new(exploration_points: xp, resources: resources, losses: losses)
    end

    private

    def compute_transport_cap
      @force.sum { |type, count| Units::REGISTRY[type][:stats][:transport].to_i * count }
    end

    # Loot base: Σ cost(u) × w(u) for non-combat units only (exploration_magnitude_v1 §2).
    # Combat units escort — they reduce losses, cost when killed, but generate no loot.
    def compute_loot_base
      @force.sum do |type, count|
        next 0 if Units.combat?(type)
        cost = Units.cost_for(type).values.sum
        cost * risk_weight(type) * count
      end
    end

    # XP base: Σ XP_BASES[type] × count, scaled by Cartographie stellaire bonus.
    def compute_xp_base(carto_level)
      base = @force.sum { |type, count| XP_BASES.fetch(type, 0) * count }
      base * (1.0 + CONFIG[:carto_xp_bonus] * carto_level)
    end

    def compute_combat_ratio
      total = @force.values.sum.to_f
      return 0.0 if total.zero?
      @force.sum { |type, count| Units::REGISTRY[type][:combat] ? count : 0 } / total
    end

    def risk_weight(type)
      category = Units::REGISTRY[type][:category]
      RISK_WEIGHTS.fetch(category, 1.0)
    end

    # Loot distributed equally across the 3 resources, capped per type by transport.
    def draw_resources(loot_base, transport_cap)
      frac     = sample_tier(CONFIG[:resource_tiers])
      total    = (frac * loot_base).floor
      per_type = total / 3
      capped   = [per_type, transport_cap].min
      { metal: capped, food: capped, thorium: capped }
    end

    def draw_xp(xp_base)
      mult = sample_tier(CONFIG[:xp_tiers])
      (mult * xp_base).round
    end

    # Per-class losses with escort and Cartographie modifiers.
    # Critical tier (last) bypasses all modifiers: fraction applied directly (exploration_magnitude_v1 §2).
    def draw_losses(combat_ratio, carto_level)
      f, critical = sample_loss_tier
      return {} if f.zero?

      escort_mult = [1.0 - CONFIG[:escort_reduction] * combat_ratio, 0.0].max
      carto_mult  = [1.0 - CONFIG[:carto_loss_reduction] * carto_level, 0.0].max

      @force.each_with_object({}) do |(type, count), losses|
        n = if critical
          (f * count).round
        else
          (f * escort_mult * carto_mult * risk_weight(type) * count).round
        end
        n = [[n, 0].max, count].min
        losses[type] = n if n > 0
      end
    end

    # Returns [fraction, is_critical]. The last loss tier is the critical tier.
    def sample_loss_tier
      tiers      = CONFIG[:loss_tiers]
      r          = @rng.rand
      cumulative = 0.0
      tiers.each_with_index do |tier, i|
        cumulative += tier[:prob]
        if r < cumulative
          lo, hi   = tier[:range]
          frac     = lo == hi ? lo : lo + @rng.rand * (hi - lo)
          return [frac, i == tiers.size - 1]
        end
      end
      lo, hi = tiers.last[:range]
      [lo + @rng.rand * (hi - lo), true]
    end

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
