# ChefSync

Sync a monolithic chef repo to a chef server. Currently only prints out changes
without actually modifying anything on the chef server.

## Installation

Add this line to your chef repo's Gemfile:

```ruby
gem 'chef-sync'
```

And then execute:

	$ bundle install

Or install it yourself as:

	$ gem install chef_sync

## Configuration

`chef-sync` requires configuration to post to Slack (only required if you want
to post to Slack) and to communicate with the Chef server via Knife and Ridley.

To configure Slack, you must set the `CHEFSYNC_SLACK_WEBHOOK_URL` environment 
variable. You can optionally also set `CHEFSYNC_SLACK_USERNAME` to set the 
username you'd like to post to Slack under, and `CHEFSYNC_SLACK_CHANNEL` to set 
the Slack channel.

You can also optionally set `CHEFSYNC_CI_BUILD_URL` and `CHEFSYNC_COMMIT_URL` 
environment variables. If you set both, they will appear as links in the Slack 
post's pretext above the results of the sync.

To configure Knife/Ridley, you must have a `.chef` directory in your PATH that 
contains a `.knife.rb` config file.

## Usage

From within your chef repo, execute the following line to see a list of
unsynced changes:

	$ bundle exec chef-sync

By default, `chef-sync` is set to dryrun mode, where `chef-sync` will tell you 
what updates would happen without actually syncing things to the Chef server, 
and to avoid posting to Slack. The output will be printed to the console
regardless of whether it's set to post to Slack.

	$ bundle exec chef-sync --help
	# help menu
	$ bundle exec chef-sync --no-dryrun
	# runs chef-sync and actually syncs changes to Chef server
	$ bundle exec chef-sync -p
	# runs chef-sync and posts output to Slack in addition to in the console

## Contributing

1. Fork it ( https://github.com/[my-github-username]/chef_sync/fork )
2. Install dependencies (`bundle install`)
3. Create your feature branch (`git checkout -b my-new-feature`)
4. Make your changes.
5. Run the tests and make sure they pass (`bundle exec rspec`)
6. Commit your changes (`git commit -am 'Add some feature'`)
7. Push to the branch (`git push origin my-new-feature`)
8. Create a new pull request.
