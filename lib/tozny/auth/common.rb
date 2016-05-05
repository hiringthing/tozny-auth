require 'openssl'
require 'base64'
require 'json'

module Tozny
  class Core
    def self.base64url_encode(str)
      Base64::strict_encode64(
          str #str to decode
        ) #remove padding
        .tr('+/', '-_') #replace + with - and / with _
        .tr('=', '')
    end
    def self.base64url_decode(str)
      Base64::strict_decode64(str.tr('-_', '+/') #replace - with + and _ with /
        .ljust(str.length+(str.length % 4), '=')) #add padding
    end
    def self.check_signature(signature, str, secret)
      expected_sig = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret, str)
      expected_sig == signature
    end
    def self.encode_and_sign(data, secret)
      encoded_data = base64url_encode(data)
      sig=OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret, encoded_data)
      encoded_sig = base64url_encode(sig)
      return {
          :signed_data => encoded_data,
          :signature => encoded_sig
      }
    end
  end
end