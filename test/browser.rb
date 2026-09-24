require_relative "test_helper"
require "puma"
require "selenium-webdriver"
require "socket"

class BrowserTest < Minitest::Test
  def setup
    socket = TCPServer.new("127.0.0.1", 0)
    port = socket.addr[1]
    socket.close
    @server = Puma::Server.new(Demo)
    @server.add_tcp_listener("127.0.0.1", port)
    @server.run

    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--headless=new")
    options.add_argument("--window-size=1280,1000")
    @browser = Selenium::WebDriver.for(:chrome, options: options)
    @browser.manage.timeouts.page_load = 15
    @browser.navigate.to("http://127.0.0.1:#{port}/")
    wait { @browser.find_elements(css: ".iti").size == 6 }
  end

  def teardown
    @browser&.quit
    @server&.stop(true)
  end

  def test_classes_assets_and_serialized_values
    assert_equal "+38761123456", form_data["contact[phone_number]"]
    assert_equal 1, @browser.find_elements(css: "input[name='contact[phone_number]']").size
    assert_equal "12px", @browser.find_element(css: ".phone-dropdown").css_value("border-radius")

    @browser.find_element(css: ".iti__selected-country").click
    search = @browser.find_element(css: ".phone-search")
    assert_equal "rgba(240, 247, 255, 1)", search.css_value("background-color")
    search.send_keys(:escape)

    @browser.execute_script("document.querySelector('input[type=tel]').disabled = true")
    refute form_data.key?("contact[phone_number]")
    @browser.execute_script("document.querySelector('input[type=tel]').disabled = false")

    phone.clear
    assert_equal "", form_data["contact[phone_number]"]
    phone.send_keys("061123456")
    assert_equal "+38761123456", form_data["contact[phone_number]"]

    errors = @browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" }
    assert_empty errors
  end

  def test_turbo_frame_insertion_removal_and_reconnection
    @browser.execute_script("document.body.insertAdjacentHTML('beforeend', '<turbo-frame id=extra src=/extra></turbo-frame>')")
    wait { @browser.find_elements(css: ".iti").size == 7 }
    assert_equal "+447400123456", form_data("extra-form")["batch[contacts][0][phone_number]"]

    @browser.execute_script("window.removedFrame = document.querySelector('#extra'); removedFrame.remove()")
    wait { @browser.execute_script("return removedFrame.querySelectorAll('.iti').length") == 0 }
    @browser.execute_script("document.body.append(removedFrame)")
    wait { @browser.find_elements(css: ".iti").size == 7 }
    assert_equal "+447400123456", form_data("extra-form")["batch[contacts][0][phone_number]"]
  end

  def test_country_change_reset_and_turbo_cache_cleanup
    @browser.find_element(css: ".iti__selected-country").click
    @browser.find_element(css: ".phone-search").send_keys("United Kingdom")
    @browser.find_element(css: ".iti__country[data-iso2='gb']").click
    phone.clear
    phone.send_keys("7400123456")
    assert_equal "+447400123456", form_data["contact[phone_number]"]

    @browser.execute_script("document.dispatchEvent(new Event('turbo:before-cache'))")
    assert_empty @browser.find_elements(css: ".iti")
    assert_equal "+447400123456", phone.attribute("value")
    @browser.execute_script("document.dispatchEvent(new Event('turbo:render'))")
    wait { @browser.find_elements(css: ".iti").size == 6 }
    assert_equal "+447400123456", form_data["contact[phone_number]"]

    phone.clear
    @browser.execute_script("document.dispatchEvent(new Event('turbo:before-cache')); document.dispatchEvent(new Event('turbo:render'))")
    assert_equal "", form_data["contact[phone_number]"]
    assert_includes @browser.find_element(css: ".iti__selected-country").attribute("aria-label"), "+44"

    @browser.find_element(css: "button[type=reset]").click
    wait { form_data["contact[phone_number]"] == "+38761123456" }
    assert_includes @browser.find_element(css: ".iti__selected-country").attribute("aria-label"), "+387"
  end

  def test_turbo_and_native_form_submissions
    phone.clear
    phone.send_keys("061123456")
    @browser.find_element(css: "input[type=submit]").click
    wait { @browser.find_elements(css: "#submitted-number").any? }
    assert_equal "+38761123456", @browser.find_element(id: "submitted-number").text
    wait { @browser.find_elements(css: ".iti").size == 6 }
    assert_equal "+447400123456", @browser.find_element(id: "submitted-national").text
    assert_equal "+12025550123", @browser.find_element(id: "submitted-international").text
    assert_equal "+4915123456789", @browser.find_element(id: "submitted-minimal").text

    @browser.navigate.back
    wait { @browser.find_elements(css: "#submitted-number").empty? && @browser.find_elements(css: ".iti").size == 6 }
    assert_equal "+38761123456", form_data["contact[phone_number]"]

    @browser.execute_script("document.querySelector('#contact-form').dataset.turbo = 'false'")
    phone.clear
    phone.send_keys("061654321")
    @browser.find_element(css: "input[type=submit]").click
    wait { @browser.find_element(id: "submitted-number").text == "+38761654321" }
    assert_equal "+38761654321", @browser.find_element(id: "submitted-number").text
  end

  def test_configuration_examples_and_mobile_layout
    assert_equal "07400 123456", @browser.find_element(id: "contact_national").attribute("value")
    assert_equal "+1 202-555-0123", @browser.find_element(id: "contact_international").attribute("value")
    assert_empty @browser.find_elements(css: "#example-fixed .iti button")
    assert_empty @browser.find_elements(css: "#example-minimal .iti__flag:not(.iti__globe), #example-minimal .phone-search")

    @browser.find_element(css: "#example-regional .iti__selected-country").click
    assert_equal "Pretraži", @browser.find_element(css: "#example-regional .phone-search").attribute("placeholder")
    countries = @browser.find_elements(css: "#example-regional .iti__country").map { |country| country.attribute("data-iso2") }
    assert_equal %w[ba hr me rs], countries.sort
    @browser.find_element(css: "#example-regional .phone-search").send_keys("zzzz")
    wait { @browser.find_element(css: "#example-regional .iti__no-results").displayed? }
    assert_equal "Nema rezultata", @browser.find_element(css: "#example-regional .iti__no-results").text
    @browser.find_element(css: "#example-regional .phone-search").send_keys(:escape)

    @browser.manage.window.resize_to(390, 844)
    assert @browser.execute_script("return document.documentElement.scrollWidth <= window.innerWidth")
    cards = @browser.find_elements(css: ".field-card")
    assert_equal cards.first.rect.x, cards.last.rect.x
    assert_operator cards.last.rect.y, :>, cards.first.rect.y
  end

  def test_options_popover
    assert_equal 6, @browser.find_elements(css: ".field-heading .info-button").size
    trigger = @browser.find_element(css: "#example-regional .field-heading .info-button")
    popup = @browser.find_element(id: "options-regional")
    refute popup.displayed?
    trigger.click
    assert popup.displayed?
    options = JSON.parse(popup.find_element(css: "code").text)
    assert_equal "ba", options["initial_country"]
    assert_equal %w[ba hr rs me], options.dig("options", "only_countries")
    assert_equal "bs", options.dig("options", "country_name_locale")
    @browser.action.send_keys(:escape).perform
    refute popup.displayed?
    trigger.click
    popup.find_element(css: "button").click
    refute popup.displayed?
    trigger.click
    @browser.action.move_to_location(5, 5).click.perform
    refute popup.displayed?
    assert_empty @browser.find_elements(id: "submitted-number")
  end

  private
    def phone
      @browser.find_element(id: "contact_phone_number")
    end

    def form_data(id = "contact-form")
      @browser.execute_script("return Object.fromEntries(new FormData(document.getElementById(arguments[0])))", id)
    end

    def wait(&block)
      Selenium::WebDriver::Wait.new(timeout: 10).until(&block)
    end
end
