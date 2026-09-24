require "bundler/setup"
require "action_controller/railtie"
require_relative "../lib/dialtone_rails"

class Demo < Rails::Application
  config.load_defaults 8.0
  config.root = __dir__
  config.eager_load = false
  config.secret_key_base = "dialtone-rails-local-demo-" * 4
  config.hosts = ["localhost", "127.0.0.1"]
  config.logger = Logger.new($stdout)
  config.log_level = :warn
  config.public_file_server.enabled = true
end

class PhonesController < ActionController::Base
  protect_from_forgery with: :exception

  EXAMPLES = [
    { name: :phone_number, label: "Separate dial code", country: "ba", value: "+38761123456", options: {} },
    { name: :national, label: "National format", country: "gb", value: "+447400123456",
      options: { separate_dial_code: false, number_display_format: "NATIONAL" } },
    { name: :international, label: "International format", country: "us", value: "+12025550123",
      options: { separate_dial_code: false, number_display_format: "INTERNATIONAL" } },
    { name: :regional, label: "Balkan countries · Bosanski", country: "ba", value: "",
      options: { only_countries: %w[ba hr rs me], country_name_locale: "bs",
        ui_translations: { search_placeholder: "Pretraži", search_empty_state: "Nema rezultata" } } },
    { name: :minimal, label: "No flags or search", country: "de", value: "+4915123456789",
      options: { show_flags: false, country_search: false } },
    { name: :fixed, label: "Fixed country · France", country: "fr", value: "",
      options: { country_selector_mode: "OFF", only_countries: ["fr"],
        separate_dial_code: false, number_display_format: "NATIONAL" } }
  ].freeze

  def index
    render :index
  end

  def create
    numbers = params.require(:contact).permit(*EXAMPLES.map { |example| example[:name] })
    redirect_to "/?#{ { contact: numbers.to_h }.to_query }", status: :see_other
  end

  def extra
    render :extra, layout: false
  end
end

Demo.initialize!
Demo.routes.draw do
  root "phones#index"
  post "/contacts", to: "phones#create"
  get "/extra", to: "phones#extra"
end
