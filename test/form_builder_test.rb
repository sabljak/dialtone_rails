require_relative "test_helper"

class FormBuilderTest < Minitest::Test
  def setup
    @view = ActionView::Base.empty
  end

  def test_renders_a_regular_rails_field_and_upstream_configuration
    input = render_field(initial_country: "BA", value: "+38761123456",
      class_names: { input: "phone-input", country_selector: "dropdown" },
      options: { separate_dial_code: false, only_countries: ["ba", "gb"] })

    assert_equal "tel", input["type"]
    assert_equal "contact[phone_number]", input["name"]
    assert_equal "contact_phone_number", input["id"]
    assert_equal "+38761123456", input["value"]
    assert_equal "phone-input", input["class"]
    assert_equal({ "initialCountry" => "ba", "classNames" => {
      "input" => "phone-input", "countrySelector" => "dropdown"
    }, "separateDialCode" => false, "onlyCountries" => ["ba", "gb"] },
      JSON.parse(input.parent["data-dialtone-options-value"]))
  end

  def test_preserves_html_options_and_other_stimulus_controllers
    data = { controller: "analytics", action: "input->analytics#track", test_id: "phone" }
    input = render_field(data: data, required: true, disabled: true,
      autocomplete: "tel", style: "border-radius: 8px", aria: { describedby: "hint" })

    assert_equal "analytics", input["data-controller"]
    assert_equal "dialtone", input.parent["data-controller"]
    assert_includes input["data-action"], "input->analytics#track"
    assert_includes input.parent["data-action"], "turbo:before-cache@document->dialtone#disconnect"
    assert input.key?("required")
    assert input.key?("disabled")
    assert_equal "tel", input["autocomplete"]
    assert_equal "hint", input["aria-describedby"]
    assert_equal "border-radius: 8px", input["style"]
    assert_equal "analytics", data[:controller]
  end

  def test_nested_fields_keep_rails_names_ids_and_labels
    html = @view.form_with(scope: :batch, url: "/contacts") do |form|
      form.fields_for(:contacts, nil, index: 2) do |contact|
        contact.label(:phone_number) + contact.dialtone_field(:phone_number)
      end
    end
    document = Nokogiri::HTML.fragment(html)
    input = document.at_css("input[type=tel]")

    assert_equal "batch[contacts][2][phone_number]", input["name"]
    assert_equal document.at_css("label")["for"], input["id"]
    assert_equal 1, document.css('input[name="batch[contacts][2][phone_number]"]').size
  end

  def test_escapes_configuration_and_input_values
    text = %q{\"><script>alert('x')</script>}
    input = render_field(value: text, class_names: { input: text },
      options: { ui_translations: { search_placeholder: text } })

    assert_equal text, input["value"]
    assert_equal text, input["class"]
    assert_equal text, JSON.parse(input.parent["data-dialtone-options-value"])
      .dig("uiTranslations", "searchPlaceholder")
    assert_empty input.document.css("script")
  end

  private
    def render_field(**options)
      html = @view.form_with(scope: :contact, url: "/contacts") do |form|
        form.dialtone_field(:phone_number, **options)
      end
      Nokogiri::HTML.fragment(html).at_css("input[type=tel]")
    end
end
