// app/javascript/controllers/chatbot_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["panel"]

    open() {
        this.panelTarget.style.right = "0px"
    }

    close() {
        this.panelTarget.style.right = "-380px"
    }
}
