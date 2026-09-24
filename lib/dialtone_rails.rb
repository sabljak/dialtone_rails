require "rails/railtie"
require_relative "dialtone_rails/version"
require_relative "dialtone_rails/form_builder"

module DialtoneRails
  class Railtie < Rails::Railtie
    initializer "dialtone_rails.form_builder" do
      ActiveSupport.on_load(:action_view) do
        ActionView::Helpers::FormBuilder.include DialtoneRails::FormBuilder
      end
    end
  end
end
