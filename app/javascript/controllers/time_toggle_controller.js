import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["localTimes", "trackTimes", "localButton", "trackButton"]

  showLocal() {
    this.localTimesTarget.style.display = "block"
    this.trackTimesTarget.style.display = "none"
    this.localButtonTarget.classList.add("clicked")
    this.trackButtonTarget.classList.remove("clicked")
  }

  showTrack() {
    this.localTimesTarget.style.display = "none"
    this.trackTimesTarget.style.display = "block"
    this.trackButtonTarget.classList.add("clicked")
    this.localButtonTarget.classList.remove("clicked")
  }
}
