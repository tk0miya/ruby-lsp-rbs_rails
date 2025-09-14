# Ruby LSP addon for RBS Rails

ruby-lsp-rbs_rails is a Ruby LSP addon for RBS Rails that generates RBS definitions on the fly for Rails applications.

## Installation

Install the gem and add to the application's Gemfile by executing:

```ruby
# Gemfile
group :development do
  gem 'ruby-lsp-rbs_rails', require: false

  gem 'rbs_rails', github: 'pocke/rbs_rails'  # 0.13 (unreleased) or later is required
end
```

After running `bundle install`, restart your Ruby LSP.

## Features

* Generate RBS definitions for models on saving a file (a.k.a. `app/models/**/*.rb`)
* Generate RBS definitions for path helpers on saving a file (a.k.a. `config/routes.rb`)

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and submit a pull request to the repo. It will be released to [rubygems.org](https://rubygems.org) after the PR merged.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tk0miya/ruby-lsp-rbs_rails. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/tk0miya/ruby-lsp-rbs_rails/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Ruby::Lsp::RbsRails project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/tk0miya/ruby-lsp-rbs_rails/blob/main/CODE_OF_CONDUCT.md).
