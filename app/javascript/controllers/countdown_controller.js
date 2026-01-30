import { Controller } from "@hotwired/stimulus"
import simplyCountdown from "simplycountdown"

export default class extends Controller {
  static targets = ["timer"]
  static values = { targetTime: String, sessionName: String }

  connect() {
    // Clear any existing countdown elements (e.g., from Turbo cache restoration)
    this.timerTarget.innerHTML = ''

    const targetDate = new Date(this.targetTimeValue)
    if (isNaN(targetDate.getTime())) {
      console.warn('Countdown: Invalid target time value')
      return
    }

    simplyCountdown(this.timerTarget, {
      year: targetDate.getFullYear(),
      month: targetDate.getMonth() + 1,
      day: targetDate.getDate(),
      hours: targetDate.getHours(),
      minutes: targetDate.getMinutes(),
      seconds: targetDate.getSeconds(),
      removeZeroUnits: true,
      zeroPad: true,
      onEnd: () => {
        const label = this.element.querySelector('.countdown-label')
        if (label) label.textContent = `${this.sessionNameValue} is live!`
        this.timerTarget.style.display = 'none'
      }
    })
  }
}
