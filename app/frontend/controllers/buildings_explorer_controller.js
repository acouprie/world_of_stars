import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['cats', 'blist', 'main']
  static values = {
    buildings: Object,
    ccReq: Object,
    locale: String,
    translations: Object,
    buildingNames: Object
  }

  connect() {
    // Initialize state
    this.selCat = 'all'
    this.selBuilding = null
    this.selLevel = 1
    this.chartInst = null

    // Get translations helper
    this.t = (key, fallback = '') => {
      const keys = key.split('.')
      let result = this.translationsValue
      for (const k of keys) {
        if (result && result[k]) {
          result = result[k]
        } else {
          return fallback || key
        }
      }
      return result || fallback || key
    }

    // Map categories with colors
    this.CAT = {
      energy: { label: this.t('category_labels.energy', 'Énergie'), color: '#c8a96e' },
      production: { label: this.t('category_labels.production', 'Production'), color: '#2ec4a0' },
      storage: { label: this.t('category_labels.storage', 'Stockage'), color: '#4e8faf' },
      infrastructure: { label: this.t('category_labels.infrastructure', 'Infrastructure'), color: '#8b7fcc' },
      orbital: { label: this.t('category_labels.orbital', 'Orbital'), color: '#2ec4a0' },
      military: { label: this.t('category_labels.military', 'Militaire'), color: '#e8622a' }
    }

    // Transform Ruby data to JS format
    this.transformBuildings()

    // Render initial state
    this.renderCats()
    this.renderList()
    this.renderDetail()
  }

  disconnect() {
    // Clean up chart instance
    if (this.chartInst) {
      this.chartInst.destroy()
      this.chartInst = null
    }
  }

  // Transform Ruby REGISTRY to JS format matching original HTML
  transformBuildings() {
    this.BUILDINGS = {}
    const registry = this.buildingsValue

    Object.entries(registry).forEach(([key, config]) => {
      const category = config.category
      const levels = config.levels

      // Transform levels array to format matching original HTML
      const data = levels.map(level => [
        level.metal,
        level.food,
        level.thorium || 0,
        level.energy_consumed || 0,
        this.getProductionValue(key, level),
        level.time
      ])

      // Get note from translations
      const note = this.t(`notes.${key}`, '')

      // Special handling for radar_satellite
      let radar = null
      let unlocks = null
      if (key === 'radar_satellite') {
        radar = this.getRadarLevels()
      }

      // Special handling for training_camp
      if (key === 'training_camp') {
        unlocks = this.getTrainingCampUnlocks()
      }

      // Special handling for bunker
      let bunker_res = null
      let bunker_sol = null
      if (key === 'bunker') {
        bunker_res = levels.map(l => l.production.resources)
        bunker_sol = levels.map(l => l.production.soldiers)
      }

      this.BUILDINGS[key] = {
        name: this.getBuildingName(key),
        cat: category,
        levels: levels.length,
        note: note,
        data: data,
        ...(radar && { radar }),
        ...(unlocks && { unlocks }),
        ...(bunker_res && { bunker_res }),
        ...(bunker_sol && { bunker_sol })
      }
    })

    // Transform CC requirements: group building levels by CC level, keep only the max building level per CC threshold
    this.CC_REQ = {}
    const ccReq = this.ccReqValue
    Object.entries(ccReq).forEach(([building, levelMap]) => {
      const byCC = {}
      Object.entries(levelMap).forEach(([blevel, cclevel]) => {
        const bl = parseInt(blevel)
        const cc = parseInt(cclevel)
        if (!byCC[cc] || bl > byCC[cc]) byCC[cc] = bl
      })
      this.CC_REQ[building] = Object.entries(byCC)
        .map(([cc, maxBl]) => [parseInt(cc), maxBl])
        .sort((a, b) => a[0] - b[0])
    })
  }

  getBuildingName(key) {
    // Use translations for building names
    return this.buildingNamesValue[key] || key
  }

  getProductionValue(buildingKey, level) {
    // For energy buildings, return production value
    if (['solar_station', 'nuclear_plant'].includes(buildingKey)) {
      return level.production
    }
    // For storage buildings, return capacity
    if (['food_silo', 'metal_warehouse', 'thorium_warehouse'].includes(buildingKey)) {
      return level.production
    }
    // For bunker, return resources value
    if (buildingKey === 'bunker') {
      return level.production.resources || 0
    }
    // For production buildings, return production rate
    return level.production || 0
  }

  getRadarLevels() {
    return [
      this.t('radar_levels.0', 'Présence flotte en orbite'),
      this.t('radar_levels.1', '+ Pseudo du propriétaire'),
      this.t('radar_levels.2', '+ Composition orbite complète'),
      this.t('radar_levels.3', '+ Présence flotte en approche'),
      this.t('radar_levels.4', '+ Pseudo flotte en approche'),
      this.t('radar_levels.5', '+ Distance (loin/proche/imminent)'),
      this.t('radar_levels.6', '+ ~35% composition approche'),
      this.t('radar_levels.7', '+ ~65% composition approche'),
      this.t('radar_levels.8', '+ ~85% composition approche'),
      this.t('radar_levels.9', '★ Vision totale — 100%, aucun fog of war')
    ]
  }

  getTrainingCampUnlocks() {
    return [
      this.t('training_camp_unlocks.0', 'Unités légères'),
      this.t('training_camp_unlocks.1', 'Légères améliorées'),
      this.t('training_camp_unlocks.2', 'Unités lourdes'),
      this.t('training_camp_unlocks.3', 'Lourdes améliorées'),
      this.t('training_camp_unlocks.4', 'Scientifiques'),
      this.t('training_camp_unlocks.5', 'Archéologues'),
      this.t('training_camp_unlocks.6', 'Malp'),
      this.t('training_camp_unlocks.7', 'UAV'),
      this.t('training_camp_unlocks.8', 'Élite (à définir)'),
      this.t('training_camp_unlocks.9', 'Spéciales (à définir)')
    ]
  }

  // Format numbers
  fmt(n) {
    if (n >= 1000000) return (n / 1000000).toFixed(1) + 'M'
    if (n >= 1000) return (n / 1000).toFixed(n >= 10000 ? 0 : 1) + 'k'
    return String(n)
  }

  // Format time
  fmtTime(s) {
    if (s < 60) return s + 's'
    if (s < 3600) return Math.floor(s / 60) + 'm ' + Math.round(s % 60) + 's'
    if (s < 86400) return Math.floor(s / 3600) + 'h ' + Math.floor((s % 3600) / 60) + 'm'
    const d = Math.floor(s / 86400)
    const h = Math.floor((s % 86400) / 3600)
    return d + 'j ' + h + 'h'
  }

  setLv(event) {
    const v = event.target.value
    this.selLevel = parseInt(v)
    const b = this.BUILDINGS[this.selBuilding]
    const lv = this.selLevel - 1
    const [metal, food, thorium, energy, prod, time] = b.data[lv]

    const levelValEl = document.getElementById('lvout')
    if (levelValEl) levelValEl.textContent = `${this.selLevel} / ${b.levels}`

    const m = document.getElementById('s-metal')
    if (m) m.textContent = this.fmt(metal)
    const f = document.getElementById('s-food')
    if (f) f.textContent = this.fmt(food)
    const t = document.getElementById('s-thor')
    if (t) t.textContent = this.fmt(thorium)
    const tm = document.getElementById('s-time')
    if (tm) tm.textContent = this.fmtTime(time)

    // Update radar info if applicable
    if (this.selBuilding === 'radar_satellite') {
      this.mainTarget.querySelectorAll('.radar-lv,.radar-txt').forEach((el, i) => {
        const row = Math.floor(i / 2)
        el.className = el.className.replace(/ ?(active|current)/g, '')
        if (row < lv) el.classList.add('active')
        else if (row === lv) el.classList.add('current')
      })
    }
  }

  renderCats() {
    const catLabels = Object.entries(this.CAT).map(([k, v]) => `
      <button class="cat-btn${this.selCat === k ? ' active' : ''}"
              data-action="click->buildings-explorer#setCat"
              data-buildings-explorer-cat-param="${k}">
        <span class="cat-dot" style="background:${v.color}"></span>${v.label}
      </button>
    `).join('')

    const allBtn = `<button class="cat-btn${this.selCat === 'all' ? ' active' : ''}"
           data-action="click->buildings-explorer#setCat"
           data-buildings-explorer-cat-param="all">
      <span class="cat-dot" style="background:#888"></span>${this.t('all_buildings', 'Tous les bâtiments')}
    </button>`

    this.catsTarget.innerHTML = allBtn + catLabels
  }

  renderList() {
    const keys = Object.keys(this.BUILDINGS).filter(k =>
      this.selCat === 'all' || this.BUILDINGS[k].cat === this.selCat
    )

    const items = keys.map(k => {
      const b = this.BUILDINGS[k]
      const selected = this.selBuilding === k ? ' sel' : ''
      return `
        <div class="bitem${selected}"
             data-action="click->buildings-explorer#select"
             data-buildings-explorer-building-param="${k}">
          <span class="bitem-dot" style="background:${this.CAT[b.cat].color}"></span>
          <span class="bitem-name">${b.name}</span>
          <span class="bitem-levels">${b.levels}</span>
        </div>
      `
    }).join('')

    this.blistTarget.innerHTML = items
  }

  renderDetail() {
    if (!this.selBuilding) {
      this.mainTarget.innerHTML = `
        <div class="placeholder">
          <div class="placeholder-icon">🏗️</div>
          <div style="font-size:16px;color:var(--muted)">${this.t('select_building', 'Sélectionne un bâtiment')}</div>
        </div>
      `
      return
    }

    const b = this.BUILDINGS[this.selBuilding]
    const lv = this.selLevel - 1
    const [metal, food, thorium, energy, prod, time] = b.data[lv]
    const col = this.CAT[b.cat].color
    const isEnergy = b.cat === 'energy'
    const isProd = b.cat === 'production'
    const isStorage = b.cat === 'storage'
    const isBunker = this.selBuilding === 'bunker'
    const isRadar = this.selBuilding === 'radar_satellite'
    const hasPortalEnergy = this.selBuilding === 'quantum_portal'
    const isMilitary = b.cat === 'military'

    let prodStatHtml = ''
    if (isEnergy) {
      prodStatHtml = `<div class="stat"><div class="stat-label">${this.t('stats.production', 'Production')}</div><div class="stat-val accent">${this.fmt(prod)}<span class="stat-unit">⚡</span></div></div>`
    } else if (isProd && prod > 0) {
      prodStatHtml = `<div class="stat"><div class="stat-label">${this.t('stats.production', 'Production')}</div><div class="stat-val green">${this.fmt(prod)}<span class="stat-unit">/h</span></div></div>`
    } else if (isStorage) {
      prodStatHtml = `<div class="stat"><div class="stat-label">${this.t('stats.capacity', 'Capacité')}</div><div class="stat-val blue">${this.fmt(prod)}</div></div>`
    } else if (isBunker) {
      prodStatHtml = `<div class="stat"><div class="stat-label">${this.t('stats.resources_protected', 'Ressources prot.')}</div><div class="stat-val green">${this.fmt(b.bunker_res[lv])}</div></div><div class="stat"><div class="stat-label">${this.t('stats.soldiers_protected', 'Soldats prot.')}</div><div class="stat-val blue">${this.fmt(b.bunker_sol[lv])}</div></div>`
    }

    let energyStatHtml = ''
    if (energy > 0) {
      energyStatHtml = `<div class="stat"><div class="stat-label">${this.t('stats.energy_consumed', 'Énergie conso.')}</div><div class="stat-val red">${energy}<span class="stat-unit">⚡</span></div></div>`
    }

    let unlockHtml = ''
    if (b.unlocks) {
      unlockHtml = `<div class="cc-card"><h3>${this.t('units_unlocked', 'Unités débloquées')}</h3><table class="cc-table">${b.unlocks.map((u, i) => `<tr><td>Niv ${i + 1}</td><td>${u}</td></tr>`).join('')}</table></div>`
    }

    let ccHtml = ''
    const req = this.CC_REQ[this.selBuilding]
    if (req && req.length > 0) {
      const buildingName = b.name.split(' ')[0]
      ccHtml = `<div class="cc-card"><h3>${this.t('cc_requirements', 'Prérequis Command Center')}</h3><table class="cc-table">${req.map(([cc, bmax]) => `<tr><td>CC niv ${cc}</td><td>→ ${buildingName} niv ${bmax} max</td></tr>`).join('')}</table></div>`
    }

    let radarHtml = ''
    if (isRadar) {
      radarHtml = `<div class="radar-card"><h3>${this.t('radar_info', 'Information révélée par niveau')}</h3>${b.radar.map((r, i) => {
        const cls = i < lv ? 'active' : i === lv ? 'current' : ''
        return `<div class="radar-row"><span class="radar-lv ${cls}">Niv ${i + 1}</span><span class="radar-txt ${cls}">${r}</span></div>`
      }).join('')}</div>`
    }

    let energySummaryHtml = ''
    if (isEnergy) {
      energySummaryHtml = `<div class="energy-card"><h3>${this.t('energy_balance', 'Bilan énergétique — planète tout au max')}</h3>
      <div class="energy-row"><span style="color:var(--muted)">${this.t('energy_summary.mines_and_farm', '3 mines + ferme niv 20')}</span><span style="color:var(--varek)">−1 434 ⚡</span></div>
      <div class="energy-row"><span style="color:var(--muted)">${this.t('energy_summary.quantum_portal', 'Portail quantique niv 10')}</span><span style="color:var(--varek)">−348 ⚡</span></div>
      <div class="energy-row"><span style="color:var(--muted)">${this.t('energy_summary.training_camp', 'training_camp niv 10')}</span><span style="color:var(--varek)">−150 ⚡</span></div>
      <div class="energy-row"><span style="color:var(--muted)">${this.t('energy_summary.military_camp', 'military_camp niv 10')}</span><span style="color:var(--varek)">−200 ⚡</span></div>
      <div class="energy-row"><span style="color:var(--muted)">${this.t('energy_summary.ship_factory', 'ship_factory niv 15')}</span><span style="color:var(--varek)">−600 ⚡</span></div>
      <div class="energy-total-row"><span>${this.t('energy_summary.total_required', 'Total requis')}</span><span>2 732 ⚡</span></div>
      <div style="margin-top:10px;font-size:11px;color:var(--subtle)">${this.t('energy_summary.config_min', 'Config min : 1 solar niv13 + 1 nuclear niv10 = 2 858 ⚡ (marge +126)')}</div>
    </div>`
    }

    const hasThor = b.data.some(r => r[2] > 0)

    this.mainTarget.innerHTML = `
      <div class="detail-header">
        <div class="detail-title">${b.name}</div>
        <div class="detail-meta">
          <span class="badge badge-${b.cat}">${this.CAT[b.cat].label}</span>
          <span style="color:var(--subtle)">${b.levels} ${this.t('stats.level', 'niveaux')}</span>
          ${energy === 0 && !isEnergy ? `<span style="color:var(--subtle)">${this.t('no_energy_consumed', '0 ⚡ consommée')}</span>` : ''}
        </div>
      </div>

      <div class="level-card">
        <div class="level-ctrl">
          <label>${this.t('stats.level', 'Niveau')}</label>
          <input type="range" min="1" max="${b.levels}" value="${this.selLevel}" step="1"
                 data-action="input->buildings-explorer#setLv">
          <span class="level-val" id="lvout">${this.selLevel} / ${b.levels}</span>
        </div>
        <div class="stats" id="stats">
          <div class="stat"><div class="stat-label">${this.t('stats.metal', 'Métal')}</div><div class="stat-val" id="s-metal">${this.fmt(metal)}</div></div>
          <div class="stat"><div class="stat-label">${this.t('stats.food', 'Nourriture')}</div><div class="stat-val" id="s-food">${this.fmt(food)}</div></div>
          ${hasThor ? `<div class="stat"><div class="stat-label">${this.t('stats.thorium', 'Thorium')}</div><div class="stat-val" id="s-thor">${this.fmt(thorium)}</div></div>` : ''}
          ${prodStatHtml}
          ${energyStatHtml}
          <div class="stat"><div class="stat-label">${this.t('stats.duration', 'Durée')}</div><div class="stat-val" id="s-time" style="font-size:13px">${this.fmtTime(time)}</div></div>
        </div>
      </div>

      ${radarHtml}

      <div class="chart-card">
        <div class="chart-title">${this.t('chart_title', 'Courbe de progression')}</div>
        <div class="legend" id="legend"></div>
        <div class="chart-wrap"><canvas id="bc" role="img" aria-label="Courbe de progression pour ${b.name}">Progression sur ${b.levels} niveaux.</canvas></div>
      </div>

      ${ccHtml}
      ${unlockHtml}
      ${energySummaryHtml}
      <div class="note">${b.note}</div>
    `

    this.buildLegend(b)
    setTimeout(() => this.buildChart(b, lv), 50)
  }

  buildLegend(b) {
    const hasThor = b.data.some(r => r[2] > 0)
    const col = this.CAT[b.cat].color
    const isEnergy = b.cat === 'energy'
    const isProd = b.cat === 'production'
    const isStorage = b.cat === 'storage'
    const isBunker = this.selBuilding === 'bunker'
    const hasProd = (isEnergy || isProd || isStorage || isBunker) && (isBunker ? b.bunker_res : b.data.map(r => r[4])).some(v => v > 0)

    let html = `<span class="lg"><span class="lgsq" style="background:#4e8faf"></span>${this.t('stats.metal', 'Métal')}</span><span class="lg"><span class="lgsq" style="background:#2ec4a0"></span>${this.t('stats.food', 'Nourriture')}</span>`
    if (hasThor) html += `<span class="lg"><span class="lgsq" style="background:#d4537e"></span>${this.t('stats.thorium', 'Thorium')}</span>`
    if (hasProd) html += `<span class="lg"><span class="lgsq" style="background:${col}"></span>${isEnergy ? this.t('stats.production', 'Énergie') : isProd ? this.t('stats.production', 'Production') : isStorage ? this.t('stats.capacity', 'Capacité') : this.t('stats.resources_protected', 'Ressources prot.')}</span>`

    document.getElementById('legend').innerHTML = html
  }

  buildChart(b, activeLv) {
    if (this.chartInst) {
      this.chartInst.destroy()
      this.chartInst = null
    }

    const labels = b.data.map((_, i) => String(i + 1))
    const metals = b.data.map(r => r[0])
    const foods = b.data.map(r => r[1])
    const thoriums = b.data.map(r => r[2])
    const prods = this.selBuilding === 'bunker' ? b.bunker_res : b.data.map(r => r[4])
    const hasThor = thoriums.some(v => v > 0)
    const isEnergy = b.cat === 'energy'
    const isProd = b.cat === 'production'
    const isStorage = b.cat === 'storage'
    const isBunker = this.selBuilding === 'bunker'
    const hasProd = (isEnergy || isProd || isStorage || isBunker) && prods.some(v => v > 0)
    const col = this.CAT[b.cat].color

    const datasets = [
      { label: this.t('stats.metal', 'Métal'), data: metals, borderColor: '#4e8faf', backgroundColor: 'rgba(78,143,175,0.06)', borderWidth: 1.5, pointRadius: 2, pointHoverRadius: 4, tension: 0.3 },
      { label: this.t('stats.food', 'Nourriture'), data: foods, borderColor: '#2ec4a0', backgroundColor: 'rgba(46,196,160,0.06)', borderWidth: 1.5, pointRadius: 2, pointHoverRadius: 4, tension: 0.3 }
    ]

    if (hasThor) {
      datasets.push({ label: this.t('stats.thorium', 'Thorium'), data: thoriums, borderColor: '#d4537e', backgroundColor: 'rgba(212,83,126,0.06)', borderWidth: 1.5, pointRadius: 2, pointHoverRadius: 4, tension: 0.3 })
    }

    if (hasProd) {
      const prodLabel = isEnergy ? this.t('stats.production', 'Énergie') : isProd ? this.t('stats.production', 'Production') : isStorage ? this.t('stats.capacity', 'Capacité') : this.t('stats.resources_protected', 'Ressources prot.')
      datasets.push({
        label: prodLabel,
        data: prods,
        borderColor: col,
        backgroundColor: 'rgba(0,0,0,0)',
        borderWidth: 2,
        borderDash: [5, 3],
        pointRadius: 2,
        pointHoverRadius: 4,
        tension: 0.3,
        yAxisID: 'y2'
      })
    }

    const cvs = document.getElementById('bc')
    if (!cvs) return

    this.chartInst = new Chart(cvs, {
      type: 'line',
      data: { labels, datasets },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            mode: 'index',
            intersect: false,
            backgroundColor: '#1c1d27',
            borderColor: '#2a2b38',
            borderWidth: 1,
            titleColor: '#a09e96',
            bodyColor: '#e8e4d8',
            callbacks: {
              label: i => `${i.dataset.label}: ${this.fmt(i.raw)}`
            }
          }
        },
        scales: {
          x: {
            grid: { color: 'rgba(255,255,255,0.04)' },
            ticks: { color: '#5e5d58', font: { size: 10 }, maxTicksLimit: 10 }
          },
          y: {
            grid: { color: 'rgba(255,255,255,0.04)' },
            ticks: { color: '#5e5d58', font: { size: 10 }, callback: v => this.fmt(v) }
          },
          ...(hasProd ? {
            y2: {
              position: 'right',
              grid: { drawOnChartArea: false },
              ticks: { color: col, font: { size: 10 }, callback: v => this.fmt(v) }
            }
          } : {})
        }
      }
    })
  }

  setCat(event) {
    const c = event.params.cat || event.currentTarget.dataset.buildingsExplorerCatParam
    this.selCat = c
    this.renderCats()
    this.renderList()
  }

  select(event) {
    const k = event.params.building || event.currentTarget.dataset.buildingsExplorerBuildingParam
    this.selBuilding = k
    this.selLevel = 1
    this.renderList()
    this.renderDetail()
  }
}
