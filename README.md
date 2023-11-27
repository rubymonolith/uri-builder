# URI::Builder

URI builder makes working with URLs in Ruby a little less awkward by chaining methods calls that alter the URL. It looks like this:

```ruby
URI.build("https://www.example.com/api/v1").path("/api/v2").query(search: "great books").uri
```

Compare that to:

```ruby
uri = URI("https://www.example.com/api/v1")
uri.path = "/api/v2"
uri.query = URI.encode_www_form(search: "great books")
uri
```

There's even a shortcut for working with URLs from ENV vars:

```ruby
URI.env("API_URL").path("/people/search").query(first_name: "Brad")
```

Compare that to:

```ruby
uri = URI ENV.fetch("API_URL")
uri.path = "/people/search"
uri.query = URI.encode_www_form(first_name: "Brad")
uri
```

Each chain creates a duplicate of the original URL, so you can transform away without worrying about thrashing the original URL object.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add uri-builder

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install uri-builder

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rubymonolith/uri-builder.
