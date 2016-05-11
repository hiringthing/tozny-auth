# Tozny::Auth

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tozny-auth'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tozny-auth

## Usage
In your template, include jQuery and the Tozny jQuery library:
```html
<script src="https://code.jquery.com/jquery-1.10.2.min.js"></script>
<script src="https://s3-us-west-2.amazonaws.com/tozny/production/interface/javascript/v2/jquery.tozny.js"></script>
<script type="text/javascript">
    $(document).ready(function() {
        $('#tozny-login').tozny("sid_52fa6d0a3a290");
    });
</script>
```

In your controller (assuming you have access to a rails-like `params` hash):
```ruby
realm_key_id = 'sid_123456789'
realm_secret = '6f75.....190a8dbc7'
tozny = Tozny::Realm.new(realm_key_id, realm_secret)

if params[:tozny_action] == 'tozny_login'
  user = tozny.check_login_locally(params[:signed_data], params[:signature])
  if user and user.is_a?Hash
    # Do some cool stuff with the user, because this was a successful login.
  else
    # Be sad (or happy in some cases) because the user did not log in successfully.
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

To build the documentation for this gem (assuming you have YARD installed), simply run `yard doc -o {your desired docs folder}`
## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tozny/sdk-ruby

