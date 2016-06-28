require 'openssl'
require 'base64'
require 'json'
require 'securerandom'

module Tozny
  # utility class for tozny-specific cryptography and encoding
  class Core

    # encodes a string according to the base64url specification, including removing padding
    # @param [String] str the string to encode
    # @return [String] the base64url-encoded string
    def self.base64url_encode(str)
      Base64::strict_encode64(
          str
        )
        .tr('+/', '-_')
        .tr('=', '')
    end

    # decodes a padding-stripped base64url string
    # @param [String] str the base64url-encoded string
    # @return [String] the decoded plaintext string
    def self.base64url_decode(str)
      Base64::strict_decode64(
          str.tr('-_', '+/')
          .ljust(str.length+(str.length % 4), '='))
        # replace - with + and _ with /
        # add padding
    end

    # checks the HMAC/SHA256 signature of a string
    # @param [String] signature the signature to check against
    # @param [String] str the signed data to check the signature against
    # @param [String] secret the secret to check the signature against
    # @return [TrueClass, FalseClass] whether the signature matched
    def self.check_signature(signature, str, secret)
      expected_sig = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret, str)
      expected_sig == signature
    end

    # base64url encodes and signs some data
    # * yields a base64url-encoded data object AND base64url-encoded signature
    # * the signature signs the base64-encoded data, NOT the raw data
    # @param [String] data the raw data to be encoded
    # @param [String] secret the secret to sign the encoded data with
    # @return [Hash] a hash including the signed_data and a signature
    def self.encode_and_sign(data, secret)
      encoded_data = base64url_encode(data)
      sig=OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), secret, encoded_data)
      encoded_sig = base64url_encode(sig)
      return {
          #behold, the rare return statement
          signed_data: encoded_data,
          signature: encoded_sig
      }
    end

    # generates a nonce (number used once)
    # @return [String] a hexadecimal nonce
    def self.generate_nonce
      OpenSSL::Digest::SHA256.hexdigest SecureRandom.random_bytes(8)
    end
  end
end