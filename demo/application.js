import { Application } from "@hotwired/stimulus"
import "@hotwired/turbo"
import DialtoneController from "dialtone-rails"
import "./application.css"

const application = Application.start()
application.register("dialtone", DialtoneController)
