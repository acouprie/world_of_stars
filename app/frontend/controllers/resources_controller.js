import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["foodStock", "foodBar", "metalStock", "metalBar", "thoriumStock", "thoriumBar"]
  static values  = {
    updatedAt: String,
    foodStock: Number, foodRate: Number, foodCapacity: Number,
    metalStock: Number, metalRate: Number, metalCapacity: Number,
    thoriumStock: Number, thoriumRate: Number, thoriumCapacity: Number
  }

  connect() {
    this.tick()
    this.interval = setInterval(() => this.tick(), 1000)
  }

  disconnect() { clearInterval(this.interval) }

  tick() {
    const elapsed = Math.max(0, (Date.now() - new Date(this.updatedAtValue).getTime()) / 1000)
    this.#update(this.foodStockTarget,    this.foodBarTarget,    this.foodStockValue,    this.foodRateValue,    this.foodCapacityValue,    elapsed)
    this.#update(this.metalStockTarget,   this.metalBarTarget,   this.metalStockValue,   this.metalRateValue,   this.metalCapacityValue,   elapsed)
    this.#update(this.thoriumStockTarget, this.thoriumBarTarget, this.thoriumStockValue, this.thoriumRateValue, this.thoriumCapacityValue, elapsed)
  }

  #update(stockEl, barEl, initial, rate, capacity, elapsed) {
    const stock = Math.min(Math.max(0, initial + rate * elapsed), capacity)
    const pct   = capacity > 0 ? Math.min(100, (stock / capacity) * 100) : 0
    stockEl.textContent = Math.floor(stock).toLocaleString()
    barEl.style.width   = `${pct.toFixed(1)}%`
    barEl.classList.toggle("opacity-50", pct >= 100)
  }
}
