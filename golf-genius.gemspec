# frozen_string_literal: true

require_relative "lib/golf_genius/version"

Gem::Specification.new do |spec|
  spec.name = "golf-genius"
  spec.version = GolfGenius::VERSION
  spec.authors = ["Aaron Christy"]
  spec.email = ["aaron@ohiogolf.org"]

  spec.summary = "Ruby bindings for the Golf Genius API"
  spec.description = "A Ruby library for accessing the Golf Genius API v2, providing read-only access to seasons, categories, directories, and events."
  spec.homepage = "https://github.com/ohiogolf/golf-genius-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://www.golfgenius.com/api/v2/docs"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["{lib}/**/*", "LICENSE", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-retry", "~> 2.0"
  spec.add_dependency "nokogiri", "~> 1.13"

  # Development dependencies
  spec.add_development_dependency "dotenv", "~> 3.2"
  spec.add_development_dependency "irb", "~> 1.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
  spec.add_development_dependency "rubocop-minitest", "~> 0.35"
  spec.add_development_dependency "vcr", "~> 6.0"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "yard", "~> 0.9"
end
