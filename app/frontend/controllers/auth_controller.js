import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['loginForm', 'registerForm', 'loginTab', 'registerTab']
  static values = { tab: { type: String, default: 'login' } }

  connect() {
    if (this.tabValue === 'register') {
      this._activate('register')
    } else {
      this._activate('login')
    }
  }

  showLogin() {
    this._activate('login')
  }

  showRegister() {
    this._activate('register')
  }

  _activate(tab) {
    const isRegister = tab === 'register'
    this.loginFormTarget.hidden = isRegister
    this.registerFormTarget.hidden = !isRegister
    this.loginTabTarget.dataset.active = String(!isRegister)
    this.registerTabTarget.dataset.active = String(isRegister)
  }
}
