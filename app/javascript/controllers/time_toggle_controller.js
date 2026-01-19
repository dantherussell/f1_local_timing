import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["localTimes", "trackTimes", "utcTimes", "localButton", "trackButton", "utcButton"]

  showLocal() {
    this.localTimesTarget.style.display = "block"
    this.trackTimesTarget.style.display = "none"
    if (this.hasUtcTimesTarget) this.utcTimesTarget.style.display = "none"
    this.localButtonTarget.classList.add("clicked")
    this.trackButtonTarget.classList.remove("clicked")
    if (this.hasUtcButtonTarget) this.utcButtonTarget.classList.remove("clicked")
  }

  showTrack() {
    this.localTimesTarget.style.display = "none"
    this.trackTimesTarget.style.display = "block"
    if (this.hasUtcTimesTarget) this.utcTimesTarget.style.display = "none"
    this.trackButtonTarget.classList.add("clicked")
    this.localButtonTarget.classList.remove("clicked")
    if (this.hasUtcButtonTarget) this.utcButtonTarget.classList.remove("clicked")
  }

  showUtc() {
    this.localTimesTarget.style.display = "none"
    this.trackTimesTarget.style.display = "none"
    if (this.hasUtcTimesTarget) this.utcTimesTarget.style.display = "block"
    if (this.hasUtcButtonTarget) this.utcButtonTarget.classList.add("clicked")
    this.localButtonTarget.classList.remove("clicked")
    this.trackButtonTarget.classList.remove("clicked")
  }
}
