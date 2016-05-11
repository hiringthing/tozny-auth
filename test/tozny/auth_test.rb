require 'test_helper'
require 'openssl'
class Tozny::AuthTest < Minitest::Test
  @@Test_Secret = 'notsosecretafterallisitnow?'
  @@New_User_Key = '-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAoBxHB+unCjuu9PoZaxRq5DE1niKlxVvx6+/naecTDfrruHfw
eWRTUmiyZzUf78bVsZydX4XDKrf5nBFgVxquRPL5UsZrDknoC+ke8CLvOQh4EgWU
fkiXzGDaJbfiXOCbEXAEl9VZ0eTpYUpS11RSvK0SRS3+QPxAiUzlsxIRGRtF3T9J
prBe9mHORN5ViewmUaOJhUWa6Np2Evv7Q/M5RVBBhXdePaaJE9J0nMfi5E176NTD
yM7FICmYlklUtn2LZS647BgnpBz6HheJWB8xw6ZL8pxALrboXz0198mJGyXNRmwA
x7I5LIvAu2QeKP2xVWB0v6xCWkO/lhAtMEvY0wIDAQABAoIBADRmDLkC3j/zGGcE
Ep2AqRrVH/8Ix8e3N41HjiySeyHwJITSe9i+hKZLrVcpg7ItGHJwFvDUDfNFEmOJ
LEZVbQMToZT9arvaZB7BxGZCiJfZtbHwMZDCoSs55yrA60wKFbW3O0mVgTe3+sjk
Ugg2iH1HBtutGbCa3WQRznq0RvQ3+8l3hDbWDKySapqKBBiGqUz9qaFAqeTMpbO3
2+pcG3sHrtOChFw1vnzn8c1o7UU5T09YSe1qT0Ct7cpdN7rAOn9CLklw7HqjJAhi
+ZU9vXYwCqgWqg5VP52CmofzlZatwM0jCozrO0gwpP44iAZ7GOvmzRDdaG59X/6n
WvrZtwECgYEA25SZiAM+iuq08VTJhOhd0BqZNTM0Bye/VrWUTanItXcsoc/efnNh
KWNqEbZDdp1LSdUsgGL5Z2CAAAaiTRmNRgIe7Y+F2UW8UVnQgakMbQJA+rxhsImu
Guu7Vd0jLQKx1F1ECfnUgCWF11v46+KBk5A5f5l5m4k1QP10sc4mmAMCgYEAuqqT
1SMtzMHf9VLCbRqBO7i5Rw+VHtA11DZhSO7EXqvSV6ya+ff76YpTxs+p0l/yk8B+
O+G5hhqZehjtMAEay6XASIBjcmuPLVsQGgPHNM9d2/PZhV4xBua7vWly6/eQ0MWW
0/O0kMljI+tujzIb323hboRRenbZCj7DFues6vECgYEAqA9kMyXIiKp7MvqiAoeW
xeCVwpIeEBvr5oGzsH1ykPFVx8NBl6bXhsYAOO43VGGvbiMqnFkkamsBjQOG1Vvp
NNwKr+hZmaI2ME19uL+aMxS2hzIH0waNqy0hhOZsNdcKJG/902TTsAEIH3zVWDVU
14xbdb4RxWmOyN80oaIXB+ECgYBVO/BW4UJXfatq1IhM005xW67WQMpBkKcTqGUR
rVzjMafROtJlE5PmlrAcVtRfaEpWpw29ABv7nQe5lcowIkD+/kdnk6BVLcHp3uvi
RRlgBtP/zD/lwxW15gORwKWmE5v/iEmPrHclqZ9oVmdcYXASvJS0Jx0hQ0VlhTUF
r3HosQKBgQC7IW8fkWdpU1E4i1oXcq/spV0Rh4+ypzlwF21jdGi8VRC0UKwqqGEk
vG7RLDJQpMqLND2KljPX+DmyJHri7Kjutt8uENIhY9dY1ETp8rR4alZaZiN6y2ya
Ok7+tYSk4rtO10wFQfcorrUnijEMDB0hX77/wuSVB4X3ERApwEjPTA==
-----END RSA PRIVATE KEY-----'
  #@@Current_User =
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
  def test_create_user
    assert @realm.user_add('false', {name=>'emanb2998'}, OpenSSL::PKey::RSA.new(@@New_User_Key).public_key.to_s)[:return] == 'ok'
  end
  def test_user_update

  end
end
