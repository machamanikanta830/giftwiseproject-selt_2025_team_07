// app/javascript/controllers/chatbot_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["panel", "button"]

    connect() {
        this.isOpen = false
        this.close() // ensure it's hidden on load
    }

    toggle(event) {
        if (event) event.preventDefault()
        this.isOpen ? this.close() : this.open()
    }

    open() {
        this.isOpen = true
        // slide IN
        this.panelTarget.style.transform = "translateX(0)";
        this.panelTarget.style.opacity = "1";
        this.panelTarget.style.pointerEvents = "auto";
    }

    close(event) {
        if (event) event.preventDefault()
        this.isOpen = false
        // slide OUT
        this.panelTarget.style.transform = "translateX(100%)";
        this.panelTarget.style.opacity = "0";
        this.panelTarget.style.pointerEvents = "none";
    }

    // Close when clicking anywhere outside sidebar + button
    clickOutside(event) {
        if (!this.isOpen) return

        // click inside panel → ignore
        if (this.panelTarget.contains(event.target)) return

        // click on the button → ignore (handled by toggle)
        const button = this.hasButtonTarget ? this.buttonTarget : null
        if (button && button.contains(event.target)) return

        this.close()
    }
}
