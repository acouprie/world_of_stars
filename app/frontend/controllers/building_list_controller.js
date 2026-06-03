import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['tab', 'card']
  static values = { active: { type: String, default: 'all' } }

  connect() {
    this.filter('all')
  }

  setFilter(event) {
    this.filter(event.params.category)
  }

  filter(category) {
    this.tabTargets.forEach(tab => {
      tab.dataset.active = String(tab.dataset.buildingListCategoryParam === category)
    })
    this.cardTargets.forEach(card => {
      card.hidden = category !== 'all' && card.dataset.category !== category
    })
  }
}
