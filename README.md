# SOF::Cycle

Parse and interact with SOF cycle notation.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add sof-cycle

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install sof-cycle

## Usage

```ruby
cycle = SOF::Cycle.load({ volume: 3, kind: :lookback, period: :day, period_count: 3 })
cycle.to_h # => { volume: 3, kind: :lookback, period: :day, period_count: 3 }
cycle.notation # => "V3L3D"
cycle.to_s # => "3x in the prior 3 days"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

This project is managed with [Reissue](https://github.com/SOFware/reissue). Releases are automated via the [shared release workflow](https://github.com/SOFware/reissue/blob/main/.github/workflows/SHARED_WORKFLOW_README.md). Trigger a release by running the "Release gem to RubyGems.org" workflow from the Actions tab.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/SOFware/sof-cycle.
