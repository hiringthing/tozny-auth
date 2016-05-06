require 'tozny/user'
require 'json'
require 'net/http'
require 'uri'

module Tozny
  class Realm
    attr_accessor :realm_key_id, :realm_secret, :api_url, :user_api

    def initialize(realm_key_id, realm_secret, api_url = nil)
      #self.realm_key_id = realm_key_id
      #self.realm_secret = realm_secret

      #set the API URL
      if !api_url.nil?
        self.api_url = api_url
      elsif !(ENV['API_URL'].nil?)
        self.api_url=ENV['API_URL']
      else
        self.api_url='https://api.tozny.com/index.php'
      end
      if !self.api_url.is_a? URI #don't try to parse a URI instance into a URI, as this will break
        self.api_url = URI.parse(self.api_url)
      end

      self.set_new_realm(realm_key_id, realm_secret)

    end

    def set_new_realm (realm_key_id, realm_secret)
      self.realm_key_id = realm_key_id
      self.realm_secret = realm_secret
      if self.user_api.is_a? ::Tozny::User
        self.user_api.set_new_realm(realm_key_id)
      else
        self.user_api = ::Tozny::User.new(realm_key_id, api_url)
      end
    end

    def raw_call(request_obj)
      request_obj[:nonce] = Tozny::Core.generate_nonce #generate the nonce
      request_obj[:expires_at] = Time.now.to_i + 5*60 # UNIX timestamp for now +5 min
      if !request_obj.key?('realm_key_id') && !request_obj.key?(:realm_key_id) #check for both string and symbol
        #TODO: how should we handle conflicts of symbol and string keys?
        request_obj[:realm_key_id] = realm_key_id
      end
      encoded_params = Tozny::Core.encode_and_sign(request_obj.to_json, realm_secret) #make a proper request of it.
      request_url = api_url #copy the URL to a local variable so that we can add the query params
      request_url.query = URI.encode_www_form encoded_params #encode signed_data and signature as query params
      #p request_url
      JSON.parse(Net::HTTP.get(request_url), {:symbolize_names => true})
    end
  end
end