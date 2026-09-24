# Dialtone Rails

A small Rails wrapper around [intl-tel-input](https://github.com/jackocnr/intl-tel-input)
for international phone fields with a country picker and number formatting.

The Ruby gem is **`dialtone_rails`**; its companion npm package is **`dialtone-rails`**.

```erb
<%= form.intl_tel_field :phone_number,
      initial_country: "ba",
      class_names: {
        input: "input",
        container: "w-full",
        country_selector: "rounded-lg shadow-lg",
        search_input: "input"
      } %>
```

## Installation

Add to your Gemfile:

```ruby
gem "dialtone_rails"
```

Install the Ruby and JavaScript packages:

```sh
bundle install
npm install dialtone-rails
```

The npm package includes intl-tel-input and its formatting utilities.

Register the controller once with your existing Stimulus application:

```js
import DialtoneController from "dialtone-rails"

application.register("dialtone", DialtoneController)
```

Import the stylesheet in your bundler-managed CSS **before your application's
layer declarations**, including Tailwind's imports:

```css
@import "dialtone-rails/styles";
```

Your bundler must support the stylesheet's `.webp` flag images. Vite handles these
automatically; with esbuild, add `--loader:.webp=file` to your build command.

## Usage

Use it with standard Rails forms and labels:

```erb
<%= form_with model: @contact do |form| %>
  <%= form.label :phone_number %>
  <%= form.intl_tel_field :phone_number,
        initial_country: "ba",
        required: true,
        autocomplete: "tel",
        class_names: { input: "input", container: "w-full" } %>
  <%= form.submit %>
<% end %>
```

## Configuration

- `initial_country:` is an ISO two-letter country code. By default no country is
  assumed. An existing international number determines its own country.
- `class_names:` is the single place to specify classes, including the input's
  classes. Slot names use snake_case and map directly to upstream `classNames`.
- `options:` accepts JSON-compatible [upstream options](https://intl-tel-input.com/docs/options).
  Use snake_case keys, including in nested hashes.
- Remaining arguments are ordinary input attributes: `id:`, `value:`, `style:`,
  `required:`, `disabled:`, `readonly:`, `autocomplete:`, `data:`, and `aria:`.

For example:

```erb
<%= form.intl_tel_field :phone_number,
      initial_country: "ba",
      options: {
        only_countries: %w[ba hr rs me],
        separate_dial_code: false,
        country_name_locale: "bs",
        ui_translations: { search_placeholder: "Pretraži" }
      } %>
```

`country_name_locale` translates country names. Use `ui_translations` for search
text and other interface strings; unspecified strings remain in English.

Options that require JavaScript callbacks or DOM elements cannot be passed from
Ruby. Leave `hidden_inputs` and `load_utils` unset; submission and formatting are
already provided.

## Styling

Omitting `class_names:` uses upstream's neutral appearance. There is no Tailwind,
Bootstrap, or application-specific theme dependency.

Add classes through `class_names:`. Available slots include `input`, `container`,
`selected_country`, `country_selector`, `search_input`, and `country_list_item`.
See the [full list of styling slots](https://intl-tel-input.com/docs/theming).

Normal unlayered application CSS overrides the gem's layered CSS. With layered
styles, declare the `intl-tel-input` layer before your application layers. If your
build assembles CSS from several entrypoints, explicitly declare the order first:

```css
@layer intl-tel-input, theme, base, components, utilities;
```

CSS variables work too:

```css
.my-phone-field {
  --iti-border-color: #ccc;
  --iti-country-selector-bg: white;
  --iti-hover-color: #f3f4f6;
}
```

Apply that class with `class_names: { container: "my-phone-field" }`. Use upstream
sizing options and CSS variables for widget positioning and input padding.

## Submitted values

The form submits the full international number under the original Rails field
name, e.g. `contact[phone_number] = "+38761123456"`, while the input displays a
readable, formatted number.

- Empty fields submit an empty string; disabled fields are omitted.
- Formatting is not validation. Incomplete numbers are not rejected, and values
  that cannot be formatted are preserved. Validate phone numbers in your Rails model.
- `strict_mode` restricts typed characters by default. Disable it with
  `options: { strict_mode: false }`.
- Use distinct names or indexed `fields_for` names for multiple inputs. Repeated
  names such as `phones[]` are unsupported.
- Submitted numbers use E.164 format; extensions require separate handling.

Native forms, Turbo submissions, form resets, and fields added through Turbo
Frames or Streams are supported. Back navigation preserves the number and country.

Without JavaScript, the helper remains a normal `type="tel"` input and submits its
raw value. If you serialize forms manually, use `FormData`; reading `.value` reads
the displayed value, not necessarily the full international number.

## Run the demo

From this repository:

```sh
bundle install
npm install
npm run build:demo
bundle exec rackup demo/config.ru --port 3001
```

Open <http://localhost:3001>. Try six phone fields with different formatting,
country, and language settings. Each field's info icon shows its configuration;
the reference below the form explains all options. Submit to see the values
received by Rails.

## License

MIT licensed. intl-tel-input and Stimulus retain their own licenses.
