require 'tozny/auth/common'

module Tozny
  class User
    attr_accessor :realm_key_id, :api_url
    def initialize(realm_key_id, api_url = nil)

      if !api_url.nil?
        self.api_url = api_url
      elsif !(ENV['API_URL'].nil?)
        self.api_url=ENV['API_URL']
      else
        self.api_url='https://api.tozny.com/index.php'
      end

      unless self.api_url.is_a? URI
        self.api_url = URI.parse(self.api_url)
      end

      self.set_new_realm(realm_key_id)
    end

    # check the status of a session
    # @param [String] session_id the session to check
    # @return [TrueClass, FalseClass] 'true' if the use has logged in with the session, false otherwise
    def check_session_status(session_id)
      raw_call({
        :method => 'user.check_session_status',
        :session_id => session_id
        }).key?(:signed_data)
    end

    # use a new realm_key_id
    # @param [String] realm_key_id
    # @return [TrueClass] will always return true
    def set_new_realm (realm_key_id)
      self.realm_key_id = realm_key_id
      true
    end

    # Generate a new login challenge session
    # @param [TrueClass, FalseClass] user_add optional: whether or not to create an enrollment challenge rather than an authentication challenge
    # @return [Hash] a challenge session (:challenge, :realm_key_id, :session_id, :qr_url, :mobile_url, :created_at, :presence = "")
    def login_challenge(user_add = nil)
      request_obj = {
        :method => 'user.login_challenge'
      }
      request_obj[:user_add] = user_add if user_add
      raw_call request_obj

    end

    # Perform a raw(ish) API call
    # @param [Hash{Symbol, String => Object}] request_obj The request to conduct. Should include a :method at the least. Prefer symbol keys to string keys
    # @return [Object] The parsed result of the request. NOTE: most types will be stringified for most requests
    def raw_call(request_obj)
      unless request_obj.key?('realm_key_id') || request_obj.key?(:realm_key_id) # check for both string and symbol
        # TODO: how should we handle conflicts of symbol and string keys?
        request_obj[:realm_key_id] = realm_key_id
      end
      request_url = api_url # copy the URL to a local variable so that we can add the query params
      request_url.query = URI.encode_www_form request_obj # encode request as query params
      #p request_url
      JSON.parse(Net::HTTP.get(request_url), :symbolize_names => true)
    end
  end
end