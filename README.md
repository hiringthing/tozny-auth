# This repository and product is deprecated. Please use https://github.com/tozny/e3db-ruby and https://tozny.com/tozid/
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

## Usage (Authentication)
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
require 'tozny/auth'
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

## Usage (SMS OTP / 2FA)

To send a one-time-password (via SMS)
```ruby
require 'tozny/auth'
realm_key_id = 'sid_123456789'
realm_secret = '6f75.....190a8dbc7'
tozny = Tozny::Realm.new(realm_key_id, realm_secret)

tozny.otp_challenge('sms-otp-6', '8005551234', nil, {foo: 'bar'})
# or alternatively (for a 6 digit OTP -- you cannot do an 8 digit OTP using the following method)
tozny.sms_otp('8005551234', {foo: 'bar'})
# or, if you don't need custom data, and you have unauthenticated OTP enabled in your realm's admin console:
tozny.user_api.otp_challenge('sms-otp-6', '8005551234')
# finally, if you already have an otp 'presence' you can use that instead of the type and destination:
tozny.otp_challenge(presence='237fa....af794')
```

To verify the OTP the end-user enters based on the session
```ruby
require 'tozny/auth'
realm_key_id = 'sid_123456789'
tozny_user = Tozny::User.new(realm_key_id) # Note: Tozny::Realm#user_api is an instance of Tozny::User pre-set to the realm

session_id = '2392e...134' # this should be the session_id you got back from otp_challenge
otp = '123456' # this should be the OTP entered by the user

if tozny_user.otp_result(session_id, otp).key?(:signed_data)
  # the OTP was correct
else
  # you can try another OTP until the session expires
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tozny/sdk-ruby

