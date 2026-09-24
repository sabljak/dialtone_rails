require_relative "lib/dialtone_rails/version"

Gem::Specification.new do |spec|
  spec.name = "dialtone_rails"
  spec.version = DialtoneRails::VERSION
  spec.authors = ["Harun"]
  spec.summary = "Rails form helper for intl-tel-input"
  spec.license = "MIT"
  spec.homepage = "https://github.com/sabljak/dialtone_rails"
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.required_ruby_version = ">= 3.2"
  spec.files = Dir["lib/**/*.rb", "README.md", "LICENSE"]

  spec.add_dependency "actionview", ">= 8.0", "< 9"
  spec.add_dependency "railties", ">= 8.0", "< 9"
end
