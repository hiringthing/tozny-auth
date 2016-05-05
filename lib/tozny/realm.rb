require 'tozny/auth/common'
require 'json'
require 'net/http'
require 'uri'

module Tozny
  class Realm
    attr_accessor :realm_key_id, :realm_secret, :api_url

    def initialize(realm_key_id, realm_secret, api_url = nil)
      self.realm_key_id = realm_key_id
      self.realm_secret = realm_secret
      if !api_url.nil?
        self.api_url = api_url
      elsif !(ENV['API_URL'].nil?)
        self.api_url=ENV['API_URL']
      else
        self.api_url='https://api.tozny.com/index.php'
      end
      self.api_url = URI.parse(self.api_url)

    end

    def set_new_realm (realm_key_id, realm_secret)
      self.realm_key_id = realm_key_id
      self.realm_secret = realm_secret
    end

    def raw_call(request_obj)
      request_obj[:nonce] = Tozny::Core.generate_nonce
      request_obj[:expires_at] = Time.now.to_i + 5*60 # UNIX timestamp for now +5 min
      if !request_obj.key?('realm_key_id') && !request_obj.key?(:realm_key_id)
        request_obj[:realm_key_id] = realm_key_id
      end
      encoded_params = Tozny::Core.encode_and_sign(request_obj.to_json, realm_secret)
      request_url = api_url
      request_url.query = URI.encode_www_form encoded_params
      p request_url
      JSON.parse(Net::HTTP.get(request_url), {:symbolize_names => true})
    end
  end
end