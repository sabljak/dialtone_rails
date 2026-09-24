module DialtoneRails
  module FormBuilder
    def intl_tel_field(method, initial_country: "", class_names: {}, options: {}, **html_options)
      classes = class_names.transform_keys { |key| key.to_s.camelize(:lower) }
      configuration = options.deep_transform_keys { |key| key.to_s.camelize(:lower) }
        .merge("initialCountry" => initial_country.to_s.downcase, "classNames" => classes)

      data = (html_options[:data] || {}).merge("dialtone-target" => "input")
      input = telephone_field(method, html_options.merge(class: classes["input"], data: data))

      @template.tag.div(input, data: {
        controller: "dialtone",
        action: "turbo:before-cache@document->dialtone#disconnect turbo:render@document->dialtone#connect",
        "dialtone-options-value" => configuration
      })
    end
  end
end
