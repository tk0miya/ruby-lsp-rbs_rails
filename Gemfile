# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in ruby-lsp-rbs_rails.gemspec
gemspec

gem "irb"
gem "rake", "~> 13.0"

gem "rbs-inline", require: false
gem "rbs_rails", github: "pocke/rbs_rails"
gem "rspec", require: false
gem "rubocop", "~> 1.21", require: false
gem "rubocop-rake", require: false
gem "rubocop-rspec", require: false
gem "ruby-lsp-rspec", require: false
gem "steep", require: false

eval_gemfile "spec/test-app/Gemfile"
