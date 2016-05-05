require 'test_helper'
class Tozny::AuthTest < Minitest::Test
  @@secret = 'notsosecretafterallisitnow?'

  def test_that_it_has_a_version_number
    refute_nil ::Tozny::Auth::VERSION
  end

  def test_test_running_works
    assert true
  end

  def test_b64url_decode
    assert ::Tozny::Core::base64url_decode('dGVzdG9kZHBhZA') == 'testoddpad'
  end
  def test_b64url_encode
    assert ::Tozny::Core::base64url_encode('testoddpad') == 'dGVzdG9kZHBhZA'
  end
  def test_check_signature
    assert ::Tozny::Core::check_signature('0e8ebea5a44f8d126102f4413335bb257a56e349a9584815a2c517c64fdc7491',
                                          'this is a test string for HMAC hashing in tozny\'s SDK-Ruby',
                                          @@secret)
  end
  def test_encode_and_sign
    assert_equal ::Tozny::Core::encode_and_sign('just yet another test...', @@secret), {
        :signed_data => "anVzdCB5ZXQgYW5vdGhlciB0ZXN0Li4u",
        :signature => "ZjU4OTk0YTdjZjYwMmQzYWViOTBlMGNkNTgxODE0MjM3MmE2MmVjMjk4NmY4NmQwZmJmZTA5YTMxYTg5MTNmOQ"
    }
  end
  def test_temp
    assert_equal ::Tozny::Realm, ::Tozny::Auth::Realm
    assert_equal ::Tozny::User, ::Tozny::Auth::User

  end
end
