module Espionnages
  class Resolver
    CONFIG = {
      a:                0.10,   # tech multiplier rate for attacker Renseignement (§6)
      b:                0.10,   # tech multiplier rate for defender Renseignement (§6)
      d0:               0.45,   # base detection coefficient (§6)
      l0:               2.5,    # base loss coefficient when detected (§6)
      q0:               0.70,   # base completeness coefficient (§6)
      depth_q_penalty:  0.10,   # completeness degrades 0.10 per depth rank above 1 (§6)
      value_noise_sigma: 0.05,  # 5% gaussian noise on revealed numeric values
    }.freeze

    DEPTHS = [
      { rank: 1, key: :buildings,    condition: :none },
      { rank: 2, key: :units,        condition: :none },
      { rank: 3, key: :resources,    condition: :none },
      { rank: 4, key: :technologies, condition: :ta_gte_td },
      { rank: 5, key: :ships,        condition: :spectre },
    ].freeze

    Result = Struct.new(:detected, :attacker_revealed, :losses, :report, keyword_init: true)

    # force          — Hash { unit_type => count } (recon units only: sonde, spectre)
    # context        — { attacker_renseignement:, defender_renseignement:, seed: }
    # defender_state — { buildings:, units:, resources:, technologies:, ships: }
    def initialize(force, context = {}, defender_state = {})
      @force          = force.transform_keys(&:to_sym).transform_values(&:to_i).reject { |_, v| v <= 0 }
      @context        = context.transform_keys(&:to_sym)
      @defender_state = defender_state
      @rng            = Random.new(@context[:seed] || Random.new_seed)
    end

    def call
      n         = @force.values.sum
      ta        = @context[:attacker_renseignement].to_i
      td        = @context[:defender_renseignement].to_i
      m_atq     = 1.0 + CONFIG[:a] * ta
      m_def     = 1.0 + CONFIG[:b] * td
      furtivite = mean_espionage(n)

      p_det    = [[CONFIG[:d0] * n / furtivite * m_def / m_atq, 0.0].max, 1.0].min
      detected = @rng.rand < p_det

      att_revealed = detected && td >= ta
      losses       = detected ? compute_losses(n, furtivite, m_atq, m_def) : {}
      report       = build_report(n, ta, td, m_atq, m_def)

      Result.new(detected: detected, attacker_revealed: att_revealed, losses: losses, report: report)
    end

    private

    # Weighted mean espionage stat; clamped away from zero to prevent division by zero.
    def mean_espionage(n)
      return 1.0 if n.zero?
      total = @force.sum { |type, count| Units::REGISTRY[type][:stats][:espionage].to_i * count }
      [total.to_f / n, 1e-6].max
    end

    def compute_losses(n, furtivite, m_atq, m_def)
      loss_frac = [[CONFIG[:l0] * m_def / (furtivite * m_atq), 0.0].max, 1.0].min
      n_losses  = [[n * loss_frac, 0.0].max.round, n].min
      return {} if n_losses.zero?
      distribute_losses(n_losses)
    end

    def distribute_losses(n_losses)
      types     = @force.keys
      total_n   = @force.values.sum.to_f
      result    = {}
      remaining = n_losses

      types.each do |type|
        break if remaining <= 0
        share  = (n_losses * @force[type] / total_n).round
        actual = [[share, @force[type]].min, remaining].min
        result[type] = actual if actual > 0
        remaining   -= actual
      end

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

    def build_report(n, ta, td, m_atq, m_def)
      q_base      = [[CONFIG[:q0] * m_atq / m_def * n / 5.0, 0.0].max, 1.0].min
      has_spectre = @force.fetch(:spectre, 0) > 0
      report      = {}

      DEPTHS.each do |depth|
        rank = depth[:rank]
        key  = depth[:key]

        next if n < rank
        next if depth[:condition] == :ta_gte_td && ta < td
        next if depth[:condition] == :spectre   && !has_spectre

        q      = [[q_base - CONFIG[:depth_q_penalty] * (rank - 1), 0.0].max, 1.0].min
        source = @defender_state[key] || {}
        report[key] = apply_completeness(source, q)
      end

      report
    end

    def apply_completeness(source, q)
      source.each_with_object({}) do |(k, v), h|
        next unless @rng.rand < q
        h[k] = apply_noise(v)
      end
    end

    def apply_noise(value)
      return value unless value.is_a?(Numeric)
      noised = value * (1.0 + CONFIG[:value_noise_sigma] * sample_normal)
      [0, noised.round].max
    end

    def sample_normal
      u1 = @rng.rand; u2 = @rng.rand
      u1 = @rng.rand while u1 <= 0.0
      Math.sqrt(-2.0 * Math.log(u1)) * Math.cos(2.0 * Math::PI * u2)
    end
  end
end
