import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  static values = {
    options: Object
  }

  connect() {
    this.select = new TomSelect(this.element, {
      ...this.defaultOptions,
      ...this.optionsValue
    })
  }

  disconnect() {
    if (this.select) {
      this.select.destroy()
    }
  }

  get defaultOptions() {
    return {
      create: false,
      allowEmptyOption: true
    }
  }
}
