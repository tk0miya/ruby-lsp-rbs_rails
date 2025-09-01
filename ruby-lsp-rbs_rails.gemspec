# frozen_string_literal: true

require_relative "lib/ruby_lsp/rbs_rails/version"

Gem::Specification.new do |spec|
  spec.name = "ruby-lsp-rbs_rails"
  spec.version = RubyLsp::RbsRails::VERSION
  spec.authors = ["Takeshi KOMIYA"]
  spec.email = ["i.tkomiya@gmail.com"]

  spec.summary = "Ruby LSP addon for rbs_rails"
  spec.description = "Ruby LSP addon for rbs_rails"
  spec.homepage = "https://github.com/tk0miya/ruby-lsp-rbs_rails"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "railties"
  spec.add_dependency "rbs_rails"
  spec.add_dependency "ruby-lsp"
end
