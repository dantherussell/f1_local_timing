import { Controller } from "@hotwired/stimulus"
import simplyCountdown from "simplycountdown"

export default class extends Controller {
  static targets = ["timer"]
  static values = { targetTime: String, sessionName: String }

  connect() {
    const targetDate = new Date(this.targetTimeValue)

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
        this.element.querySelector('.countdown-label').textContent = `${this.sessionNameValue} is live!`
        this.timerTarget.style.display = 'none'
      }
    })
  }
}
