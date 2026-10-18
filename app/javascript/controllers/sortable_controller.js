import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import Sortable from "sortablejs"

// Connects to data-controller="sortable"
export default class extends Controller {
  static values = { listId: Number, group: { type: String, default: "shared" } }

  connect() {
    this.sortable = Sortable.create(this.element, {
      group: this.groupValue,
      animation: 180,
      draggable: "[data-card-id]",
      // The fallback renders the dragged card as a DOM element, so it can be tilted and lifted with CSS.
      forceFallback: true,
      fallbackOnBody: true,
      ghostClass: "card-ghost",
      dragClass: "card-drag",
      emptyInsertThreshold: 24,
      onMove: this.highlightTarget,
      onEnd: this.onEnd.bind(this)
    })

    // A drag ends with a mouseup over the card's link; swallow the click that follows it.
    this.suppressClick = (event) => {
      if (!this.justDragged) return
      event.preventDefault()
      event.stopPropagation()
    }
    this.element.addEventListener("click", this.suppressClick, true)
  }

  disconnect() {
    this.element.removeEventListener("click", this.suppressClick, true)
    this.sortable?.destroy()
  }

  highlightTarget(event) {
    document.querySelectorAll(".drop-target").forEach((zone) => zone !== event.to && zone.classList.remove("drop-target"))
    event.to.classList.add("drop-target")
  }

  async onEnd(event) {
    document.querySelectorAll(".drop-target").forEach((zone) => zone.classList.remove("drop-target"))
    this.justDragged = true
    setTimeout(() => { this.justDragged = false }, 0)

    const { item, from, to, oldDraggableIndex, newDraggableIndex } = event
    if (from === to && oldDraggableIndex === newDraggableIndex) return

    let response = null
    try {
      response = await fetch(item.dataset.moveUrl, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content
        },
        body: JSON.stringify({ list_id: Number(to.dataset.sortableListIdValue), position: newDraggableIndex + 1 })
      })
    } catch (error) {
      console.error("Kart taşınamadı:", error)
    }

    if (response?.ok) {
      // Morph the board so counters, statuses and date badges reflect the move.
      Turbo.visit(window.location.href, { action: "replace" })
    } else {
      console.error("Kart taşınamadı:", response?.status)
      this.revert(item, from, oldDraggableIndex)
    }
  }

  revert(item, from, index) {
    const cards = Array.from(from.querySelectorAll(":scope > [data-card-id]")).filter((card) => card !== item)
    from.insertBefore(item, cards[index] || null)
  }
}
