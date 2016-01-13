# ChefSync

Sync a monolithic chef repo to a chef server. Currently only prints out changes
without actually modifying anything on the chef server.

## Installation

Add this line to your chef repo's Gemfile:

```ruby
gem 'chef-sync'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install chef_sync

## Usage

From within your chef repo, execute the following line to see a list of
unsynced changes:

	$ bundle exec chef-sync

## Contributing

1. Fork it ( https://github.com/[my-github-username]/chef_sync/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
