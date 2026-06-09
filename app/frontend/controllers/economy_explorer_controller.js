import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    biomeBonuses: Object,
    biomes: Array,
    locale: String,
    translations: Object,
    icons: Object
  }

  static targets = ["nav", "main"]

  connect() {
    this.currentSection = "energy"
    this.renderNav()
    this.renderSection("energy")
  }

  t(keyPath) {
    const keys = keyPath.split(".")
    let val = this.translationsValue
    for (const k of keys) {
      val = val?.[k]
      if (val === undefined) return keyPath
    }
    return val ?? keyPath
  }

  icon(key, size = 20) {
    const src = this.iconsValue[key]
    if (!src) return ""
    return `<img src="${src}" alt="${key}" style="width:${size}px;height:${size}px;object-fit:contain;vertical-align:middle;display:inline-block">`
  }

  switchSection(e) {
    this.currentSection = e.currentTarget.dataset.section
    this.renderNav()
    this.renderSection(this.currentSection)
  }

  renderNav() {
    const sections = ["energy", "resources", "biomes", "storage", "bunker"]
    const icons    = { energy: "⚡", resources: "⚗️", biomes: "🌍", storage: "📦", bunker: "🛡️" }
    const colors   = {
      energy:    "var(--primary)",
      resources: "var(--quantum)",
      biomes:    "var(--secondary)",
      storage:   "#8b7fcc",
      bunker:    "var(--varek)"
    }

    this.navTarget.innerHTML = sections.map(s => `
      <button class="nav-btn${s === this.currentSection ? " active" : ""}"
              data-section="${s}"
              data-action="click->economy-explorer#switchSection">
        <span class="nav-icon" style="color:${colors[s]}">${icons[s]}</span>
        <span class="nav-text">${this.t(`sections.${s}.label`)}</span>
      </button>
    `).join("")
  }

  renderSection(name) {
    const renderers = {
      energy:    () => this.renderEnergy(),
      resources: () => this.renderResources(),
      biomes:    () => this.renderBiomes(),
      storage:   () => this.renderStorage(),
      bunker:    () => this.renderBunker()
    }
    this.mainTarget.innerHTML = renderers[name]?.() ?? ""
    if (name === "biomes") {
      requestAnimationFrame(() => {
        this.mountFormulaChart()
        this.mountBiomesChart()
      })
    }
  }

  // ─── Energy ────────────────────────────────────────────────────────────────

  renderEnergy() {
    const details = [1, 2, 3].map(i =>
      `<div class="detail-item"><span class="detail-dot" style="color:var(--primary)">▸</span>${this.t(`sections.energy.detail_${i}`)}</div>`
    ).join("")

    return `
      <div class="section-header">
        <div class="section-icon" style="background:rgba(200,169,110,0.12);color:var(--primary)">⚡</div>
        <div>
          <div class="section-title">${this.t("sections.energy.title")}</div>
          <div class="section-sub">${this.t("sections.energy.subtitle")}</div>
        </div>
      </div>

      <div class="card">
        <h3 class="card-label">${this.t("sections.energy.concept_title")}</h3>
        <div class="concept-grid">
          <div class="concept-item energy-item">
            <div class="concept-icon">${this.icon("energy", 28)}</div>
            <div class="concept-name">${this.t("sections.energy.energy_label")}</div>
            <div class="concept-type">${this.t("sections.energy.capacity_type")}</div>
            <div class="concept-desc">${this.t("sections.energy.energy_desc")}</div>
          </div>
          <div class="concept-item stock-item">
            <div class="concept-icon" style="display:flex;gap:4px;align-items:center">${this.icon("metal", 22)}${this.icon("food", 22)}${this.icon("thorium", 22)}</div>
            <div class="concept-name">${this.t("sections.energy.stock_label")}</div>
            <div class="concept-type">${this.t("sections.energy.stock_type")}</div>
            <div class="concept-desc">${this.t("sections.energy.stock_desc")}</div>
          </div>
        </div>
      </div>

      <div class="card">
        <h3 class="card-label">${this.t("sections.energy.rule_title")}</h3>
        <div class="rule-box">
          <div class="rule-icon">⚠️</div>
          <div class="rule-text">${this.t("sections.energy.rule_text")}</div>
        </div>
        <div class="detail-list">${details}</div>
      </div>

      <div class="card">
        <h3 class="card-label">${this.t("sections.energy.producers_title")}</h3>
        <table class="data-table">
          <thead>
            <tr>
              <th>${this.t("table.building")}</th>
              <th>${this.t("table.type")}</th>
              <th>${this.t("table.note")}</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td class="em" style="color:var(--primary)">${this.t("buildings.solar_station")}</td>
              <td>${this.t("sections.energy.prod_continuous")}</td>
              <td style="color:var(--muted)">${this.t("sections.energy.solar_note")}</td>
            </tr>
            <tr>
              <td class="em" style="color:var(--primary)">${this.t("buildings.nuclear_plant")}</td>
              <td>${this.t("sections.energy.prod_continuous")}</td>
              <td style="color:var(--muted)">${this.t("sections.energy.nuclear_note")}</td>
            </tr>
          </tbody>
        </table>
      </div>
    `
  }

  // ─── Resources ─────────────────────────────────────────────────────────────

  renderResources() {
    const resItems = [
      { key: "metal",   color: "var(--primary)",   building: "buildings.metal_mine" },
      { key: "food",    color: "var(--quantum)",   building: "buildings.farm" },
      { key: "thorium", color: "var(--secondary)", building: "buildings.thorium_mine" }
    ]

    const resCards = resItems.map(r => `
      <div class="res-card" style="border-color:${r.color}30">
        <div class="res-icon">${this.icon(r.key, 36)}</div>
        <div class="res-name" style="color:${r.color}">${this.t(`resources.${r.key}`)}</div>
        <div class="res-building">${this.t("sections.resources.produced_by")} ${this.t(r.building)}</div>
      </div>
    `).join("")

    return `
      <div class="section-header">
        <div class="section-icon" style="background:rgba(46,196,160,0.12);color:var(--quantum)">⚗️</div>
        <div>
          <div class="section-title">${this.t("sections.resources.title")}</div>
          <div class="section-sub">${this.t("sections.resources.subtitle")}</div>
        </div>
      </div>

      <div class="res-grid">${resCards}</div>

      <div class="card">
        <h3 class="card-label">${this.t("sections.resources.uses_title")}</h3>
        <table class="data-table">
          <thead>
            <tr>
              <th>${this.t("table.use")}</th>
              <th>${this.t("table.resources_needed")}</th>
            </tr>
          </thead>
          <tbody>
            <tr><td>${this.t("sections.resources.use_construction")}</td><td>${this.t("sections.resources.use_construction_res")}</td></tr>
            <tr><td>${this.t("sections.resources.use_research")}</td><td>${this.t("sections.resources.use_research_res")}</td></tr>
            <tr><td>${this.t("sections.resources.use_units")}</td><td>${this.t("sections.resources.use_units_res")}</td></tr>
          </tbody>
        </table>
        <div class="explorer-link"><a href="/docs/buildings?cat=production">${this.t("view_in_buildings")}</a></div>
      </div>
    `
  }

  // ─── Biomes ─────────────────────────────────────────────────────────────────

  renderBiomes() {
    const biomes  = this.biomesValue
    const bonuses = this.biomeBonusesValue

    const rows = biomes.map(b => {
      const bk      = bonuses[b] || {}
      const kMetal  = bk.metal   || 0
      const kFood   = bk.food    || 0
      const kThorium = bk.thorium || 0
      const total   = kMetal + kFood + kThorium
      return `
        <tr>
          <td class="biome-name">${this.t(`biomes.${b}`)}</td>
          <td class="${kMetal   > 0 ? "k-val metal"   : "zero"}">${kMetal   > 0 ? kMetal.toFixed(1)   : "—"}</td>
          <td class="${kFood    > 0 ? "k-val food"    : "zero"}">${kFood    > 0 ? kFood.toFixed(1)    : "—"}</td>
          <td class="${kThorium > 0 ? "k-val thorium" : "zero"}">${kThorium > 0 ? kThorium.toFixed(1) : "—"}</td>
          <td class="total-k">${total.toFixed(1)}</td>
          <td class="profile">${this.t(`biome_profiles.${b}`)}</td>
        </tr>
      `
    }).join("")

    return `
      <div class="section-header">
        <div class="section-icon" style="background:rgba(78,143,175,0.12);color:var(--secondary)">🌍</div>
        <div>
          <div class="section-title">${this.t("sections.biomes.title")}</div>
          <div class="section-sub">${this.t("sections.biomes.subtitle")}</div>
        </div>
      </div>

      <div class="card">
        <h3 class="card-label">${this.t("sections.biomes.formula_title")}</h3>
        <div class="formula-block">
          <div class="formula-text">taux_final = base + k × √base</div>
        </div>
        <div class="note">${this.t("sections.biomes.formula_note")}</div>
      </div>

      <div class="card">
        <h3 class="card-label">${this.t("sections.biomes.chart_bonus_title")}</h3>
        <div class="chart-wrap"><canvas id="formulaChart"></canvas></div>
      </div>

      <div class="card">
        <h3 class="card-label">${this.t("sections.biomes.table_title")}</h3>
        <div style="overflow-x:auto">
          <table class="data-table biome-table">
            <thead>
              <tr>
                <th>${this.t("table.biome")}</th>
                <th style="color:var(--primary)">${this.icon("metal", 14)} ${this.t("resources.metal")} (k)</th>
                <th style="color:var(--quantum)">${this.icon("food", 14)} ${this.t("resources.food")} (k)</th>
                <th style="color:var(--secondary)">${this.icon("thorium", 14)} ${this.t("resources.thorium")} (k)</th>
                <th>${this.t("table.total")}</th>
                <th>${this.t("table.profile")}</th>
              </tr>
            </thead>
            <tbody>${rows}</tbody>
          </table>
        </div>
      </div>

      <div class="card">
        <h3 class="card-label">${this.t("sections.biomes.chart_title")}</h3>
        <div class="chart-wrap-lg"><canvas id="biomesChart"></canvas></div>
        <div class="legend">
          <div class="lg">${this.icon("metal", 14)}<div class="lgsq" style="background:var(--primary)"></div>${this.t("resources.metal")}</div>
          <div class="lg">${this.icon("food", 14)}<div class="lgsq" style="background:var(--quantum)"></div>${this.t("resources.food")}</div>
          <div class="lg">${this.icon("thorium", 14)}<div class="lgsq" style="background:var(--secondary)"></div>${this.t("resources.thorium")}</div>
        </div>
      </div>
    `
  }

  // ─── Storage ────────────────────────────────────────────────────────────────

  renderStorage() {
    const details = [1, 2].map(i =>
      `<div class="detail-item"><span class="detail-dot" style="color:#8b7fcc">▸</span>${this.t(`sections.storage.detail_${i}`)}</div>`
    ).join("")

    return `
      <div class="section-header">
        <div class="section-icon" style="background:rgba(139,127,204,0.12);color:#8b7fcc">📦</div>
        <div>
          <div class="section-title">${this.t("sections.storage.title")}</div>
          <div class="section-sub">${this.t("sections.storage.subtitle")}</div>
        </div>
      </div>

      <div class="card">
        <h3 class="card-label">${this.t("sections.storage.buildings_title")}</h3>
        <table class="data-table">
          <thead>
            <tr>
              <th>${this.t("table.building")}</th>
              <th>${this.t("table.resource")}</th>
              <th>${this.t("table.max_capacity")}</th>
              <th>${this.t("table.energy")}</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td class="em" style="color:var(--primary)">${this.t("buildings.metal_warehouse")}</td>
              <td style="color:var(--primary);display:flex;align-items:center;gap:6px">${this.icon("metal", 16)}${this.t("resources.metal")}</td>
              <td>8 000 000</td>
              <td class="zero">0 ⚡</td>
            </tr>
            <tr>
              <td class="em" style="color:var(--quantum)">${this.t("buildings.food_silo")}</td>
              <td style="color:var(--quantum);display:flex;align-items:center;gap:6px">${this.icon("food", 16)}${this.t("resources.food")}</td>
              <td>8 000 000</td>
              <td class="zero">0 ⚡</td>
            </tr>
            <tr>
              <td class="em" style="color:var(--secondary)">${this.t("buildings.thorium_warehouse")}</td>
              <td style="color:var(--secondary);display:flex;align-items:center;gap:6px">${this.icon("thorium", 16)}${this.t("resources.thorium")}</td>
              <td>8 000 000</td>
              <td class="zero">0 ⚡</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="card">
        <h3 class="card-label">${this.t("sections.storage.overflow_title")}</h3>
        <div class="rule-box warning">
          <div class="rule-icon">⚠️</div>
          <div class="rule-text">${this.t("sections.storage.overflow_rule")}</div>
        </div>
        <div class="detail-list">${details}</div>
        <div class="explorer-link"><a href="/docs/buildings?cat=storage">${this.t("view_in_buildings")}</a></div>
      </div>
    `
  }

  // ─── Bunker ─────────────────────────────────────────────────────────────────

  renderBunker() {
    const details = [1, 2, 3].map(i =>
      `<div class="detail-item"><span class="detail-dot" style="color:var(--varek)">▸</span>${this.t(`sections.bunker.detail_${i}`)}</div>`
    ).join("")

    return `
      <div class="section-header">
        <div class="section-icon" style="background:rgba(232,98,42,0.12);color:var(--varek)">🛡️</div>
        <div>
          <div class="section-title">${this.t("sections.bunker.title")}</div>
          <div class="section-sub">${this.t("sections.bunker.subtitle")}</div>
        </div>
      </div>

      <div class="card">
        <h3 class="card-label">${this.t("sections.bunker.concept_title")}</h3>
        <div class="bunker-grid">
          <div class="bunker-slot">
            <div class="bunker-slot-icon">💰</div>
            <div class="bunker-slot-label">${this.t("sections.bunker.resources_label")}</div>
            <div class="bunker-slot-desc">${this.t("sections.bunker.resources_desc")}</div>
          </div>
          <div class="bunker-slot">
            <div class="bunker-slot-icon">⚔️</div>
            <div class="bunker-slot-label">${this.t("sections.bunker.soldiers_label")}</div>
            <div class="bunker-slot-desc">${this.t("sections.bunker.soldiers_desc")}</div>
          </div>
        </div>
        <div class="note" style="margin-top:12px">${this.t("sections.bunker.shared_note")}</div>
      </div>

      <div class="card">
        <h3 class="card-label">${this.t("sections.bunker.rule_title")}</h3>
        <div class="rule-box">
          <div class="rule-icon">⚔️</div>
          <div class="rule-text">${this.t("sections.bunker.rule_text")}</div>
        </div>
        <div class="detail-list">${details}</div>
        <div class="explorer-link"><a href="/docs/buildings?building=bunker">${this.t("view_in_buildings")}</a></div>
      </div>
    `
  }

  // ─── Charts ──────────────────────────────────────────────────────────────────

  mountFormulaChart() {
    const canvas = document.getElementById("formulaChart")
    if (!canvas || typeof Chart === "undefined") return

    const baseValues = Array.from({ length: 51 }, (_, i) => i * 10)
    const kDefs = [
      { k: 1.0, color: "#4e8faf" },
      { k: 2.0, color: "#c8a96e" },
      { k: 3.0, color: "#2ec4a0" }
    ]

    new Chart(canvas, {
      type: "line",
      data: {
        labels: baseValues,
        datasets: kDefs.map(({ k, color }) => ({
          label: `k = ${k.toFixed(1)}`,
          data: baseValues.map(b => +(k * Math.sqrt(b)).toFixed(1)),
          borderColor: color,
          backgroundColor: "transparent",
          borderWidth: 2,
          pointRadius: 0,
          tension: 0.3
        }))
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { labels: { color: "#a09e96", font: { size: 11 } } } },
        scales: {
          x: {
            ticks: { color: "#5e5d58", maxTicksLimit: 10 },
            grid: { color: "#2a2b38" },
            title: { display: true, text: this.t("sections.biomes.formula_x_axis"), color: "#5e5d58", font: { size: 11 } }
          },
          y: {
            ticks: { color: "#5e5d58" },
            grid: { color: "#2a2b38" },
            title: { display: true, text: this.t("sections.biomes.formula_y_axis"), color: "#5e5d58", font: { size: 11 } }
          }
        }
      }
    })
  }

  mountBiomesChart() {
    const canvas = document.getElementById("biomesChart")
    if (!canvas || typeof Chart === "undefined") return

    const biomes  = this.biomesValue
    const bonuses = this.biomeBonusesValue
    const labels  = biomes.map(b => this.t(`biomes.${b}`))

    new Chart(canvas, {
      type: "bar",
      data: {
        labels,
        datasets: [
          {
            label: this.t("resources.metal"),
            data: biomes.map(b => bonuses[b]?.metal || 0),
            backgroundColor: "rgba(200,169,110,0.7)",
            borderColor: "#c8a96e",
            borderWidth: 1
          },
          {
            label: this.t("resources.food"),
            data: biomes.map(b => bonuses[b]?.food || 0),
            backgroundColor: "rgba(46,196,160,0.7)",
            borderColor: "#2ec4a0",
            borderWidth: 1
          },
          {
            label: this.t("resources.thorium"),
            data: biomes.map(b => bonuses[b]?.thorium || 0),
            backgroundColor: "rgba(78,143,175,0.7)",
            borderColor: "#4e8faf",
            borderWidth: 1
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { labels: { color: "#a09e96", font: { size: 11 } } } },
        scales: {
          x: {
            ticks: { color: "#5e5d58", maxRotation: 45 },
            grid: { color: "#2a2b38" }
          },
          y: {
            max: 3.5,
            ticks: { color: "#5e5d58", stepSize: 0.5 },
            grid: { color: "#2a2b38" },
            title: { display: true, text: "k", color: "#5e5d58", font: { size: 11 } }
          }
        }
      }
    })
  }
}
