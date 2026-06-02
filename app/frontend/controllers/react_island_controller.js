import { Controller } from '@hotwired/stimulus'
import { createElement } from 'react'
import { createRoot } from 'react-dom/client'

const islands = import.meta.glob('../islands/**/index.jsx', { eager: true })

function resolveComponent(name) {
  const key = Object.keys(islands).find(k => k.endsWith(`/${name}/index.jsx`))
  return key ? islands[key].default : null
}

export default class extends Controller {
  connect() {
    const name = this.element.dataset.reactComponent
    if (!name) return

    let props = {}
    try {
      props = JSON.parse(this.element.dataset.props || '{}')
    } catch (e) {
      console.error('[react-island] Invalid props JSON for', name, e)
      return
    }

    const Component = resolveComponent(name)
    if (!Component) {
      console.warn('[react-island] Component not found:', name)
      return
    }

    this.root = createRoot(this.element)
    this.root.render(createElement(Component, props))
  }

  disconnect() {
    this.root?.unmount()
    this.root = null
  }
}
