import '@hotwired/turbo-rails'
import { Application } from '@hotwired/stimulus'
import './application.css'

const application = Application.start()
application.debug = false
window.Stimulus = application

// Auto-register Stimulus controllers from app/frontend/controllers/
const controllers = import.meta.glob('../controllers/**/*_controller.{js,ts}', { eager: true })
Object.entries(controllers).forEach(([path, module]) => {
  const name = path
    .replace('../controllers/', '')
    .replace(/_controller\.(js|ts)$/, '')
    .replace(/\//g, '--')
    .replace(/_/g, '-')
  application.register(name, module.default)
})
