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

    # use a new realm_key_id and realm_secret. updates the user_api handle to reflect this change as well.
    # @param [String] realm_key_id
    # @param [String] realm_secret
    # @return [TrueClass] will always return true
    def set_new_realm (realm_key_id, realm_secret)
      self.realm_key_id = realm_key_id
      self.realm_secret = realm_secret
      if self.user_api.is_a? ::Tozny::User
        self.user_api.set_new_realm(realm_key_id)
      else
        self.user_api = ::Tozny::User.new(realm_key_id, api_url)
      end
      true
    end

    # verify a login and extract user information from a signed packet forwarded to the server
    # @param [String] signed_data the base64URL data to validate
    # @param [String] signature the string representation of the signature to check the login with
    # @return [Hash, FalseClass] the login information or false if the login did not check out
    def check_login_locally(signed_data, signature)
      if check_signature(signed_data, signature)
        JSON.parse(::Tozny::Core.base64url_decode(signed_data))
      else
        false
      end
    end

    # verify a login from a user and session id. Does not return complete login information.
    # @param [String] user_id the user_id of the login to check
    # @param [String] session_id the session_id of the login to check
    # @return [Hash] the return from the API
    def check_login_via_api(user_id, session_id) #NOTE: this only returns true/false. You need to parse the data locally. See Tozny::Core.base64url_decode
      raw_call({
        :method => 'realm.check_valid_login',
        :user_id => user_id,
        :session_id => session_id
      })[:return] == 'true'
    end

    # Add a user to a closed realm
    # @param [String] defer 'true' or 'false', defines whether the user should be deferred to later be completed by the app
    # @param [Hash] metadata any metadata to be added to the user_meta
    # @param [String, OpenSSL::PKey::RSA] pub_key the public key of the user to be added. Only necessary
    # @return [Hash, FalseClass] the user in its current (incomplete if defer is 'true' state)
    def user_add(defer = 'false', metadata, pub_key)
      if pub_key.is_a? String
        pub_key = OpenSSL::PKey::RSA.new pub_key
      end
      pub_key = pub_key.public_key if pub_key.private?

      request_obj = {
          :method => 'realm.user_add'
      }
      if defer == 'false'
        throw :must_have_pub_key_if_deferred if pub_key.nil?
        request_obj[:pub_key] = pub_key
      end

      unless metadata.nil?
        extra_fields = Tozny::Core.base64url_encode(metadata.to_json)
        request_obj[:extra_fields] = extra_fields
      end

      user = raw_call request_obj
      return false unless user[:return] == 'ok'
      user
    end

    def raw_call(request_obj)
      request_obj[:nonce] = Tozny::Core.generate_nonce #generate the nonce
      request_obj[:expires_at] = Time.now.to_i + 5*60 # UNIX timestamp for now +5 min TODO: does this work with check_login_via_api, or should it default to a passed in expires_at?
      unless request_obj.key?('realm_key_id') || request_obj.key?(:realm_key_id) #check for both string and symbol
        #TODO: how should we handle conflicts of symbol and string keys?
        request_obj[:realm_key_id] = realm_key_id
      end
      encoded_params = Tozny::Core.encode_and_sign(request_obj.to_json, realm_secret) #make a proper request of it.
      request_url = api_url #copy the URL to a local variable so that we can add the query params
      request_url.query = URI.encode_www_form encoded_params #encode signed_data and signature as query params
      #p request_url
      JSON.parse(Net::HTTP.get(request_url), {:symbolize_names => true}) #TODO: handle errors
    end
  end
end