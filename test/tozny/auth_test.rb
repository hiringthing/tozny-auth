require 'test_helper'
class Tozny::AuthTest < Minitest::Test
  @@Test_Secret = 'notsosecretafterallisitnow?'

  def setup
    @realm = ::Tozny::Realm.new('SEQRDSTAR', 'DEADBEEF3', 'http://api.local.tozny.com:8090/index.php')
    @user = ::Tozny::User.new('SEQRDSTAR', 'http://api.local.tozny.com:8090/index.php')
  end

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
                                          @@Test_Secret)
  end
  def test_encode_and_sign
    assert_equal ({
        :signed_data => 'anVzdCB5ZXQgYW5vdGhlciB0ZXN0Li4u',
        :signature => '9YmUp89gLTrrkODNWBgUI3KmLsKYb4bQ-_4JoxqJE_k'
    }), ::Tozny::Core::encode_and_sign('just yet another test...', @@Test_Secret)
  end
  def test_realm_call
    assert @realm.raw_call({:method=>'realm.realm_get'})[:return] == 'ok'
  end
  def test_smoke_test_call
    assert @user.raw_call({:method => 'test.smoke', :do_smoke => TRUE})[:return] == 'ok'
  end
  def test_smoke_test_call_via_realm
    assert @realm.user_api.raw_call({:method => 'test.smoke', :do_smoke => TRUE})[:return] == 'ok'
  end
end
