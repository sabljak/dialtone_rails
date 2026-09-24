import { Controller } from "@hotwired/stimulus"
import intlTelInput from "intl-tel-input/intlTelInputWithUtils"

export default class extends Controller {
  static targets = ["input"]
  static values = { options: Object }

  connect() {
    if (this.instance) return

    this.input = this.inputTarget
    const value = this.input.value
    const country = this.input.dataset.dialtoneCountry ?? this.optionsValue.initialCountry
    this.instance = intlTelInput(this.input, {
      ...this.optionsValue,
      initialCountry: country
    })
    this.instance.setSelectedCountry(country || "")
    this.instance.setNumber(value)
    this.listeners = new AbortController()
    const events = { signal: this.listeners.signal }

    this.input.form?.addEventListener("formdata", (event) => {
      const name = this.input.name
      if (name && !this.input.matches(":disabled") && event.formData.has(name)) {
        event.formData.set(name, this.number)
      }
    }, events)

    this.input.form?.addEventListener("reset", (event) => {
      queueMicrotask(() => {
        if (this.instance && !event.defaultPrevented) {
          const value = this.input.value
          this.instance.setSelectedCountry(this.optionsValue.initialCountry || "")
          this.instance.setNumber(value)
        }
      })
    }, events)
  }

  disconnect() {
    if (!this.instance) return

    this.input.value = this.number
    this.input.dataset.dialtoneCountry = this.instance.getSelectedCountry()?.iso2 || ""
    this.listeners.abort()
    this.instance.destroy()
    this.instance = null
  }

  get number() {
    if (this.input.value.trim()) {
      return this.instance.getNumber() || this.input.value
    }
    return ""
  }
}
