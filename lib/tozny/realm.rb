require 'tozny/user'
require 'json'
require 'net/http'
require 'uri'

# rubocop:disable Metrics/PerceivedComplexity

module Tozny
  class Realm
    attr_accessor :realm_key_id, :realm_secret, :api_url, :user_api

    def initialize(realm_key_id, realm_secret, api_url = nil)
      # set the API URL
      if !api_url.nil?
        self.api_url = api_url
      elsif !(ENV['API_URL'].nil?)
        self.api_url = ENV['API_URL']
      else
        self.api_url = 'https://api.tozny.com/index.php'
      end
      unless self.api_url.is_a? URI # don't try to parse a URI instance into a URI, as this will break
        self.api_url = URI.parse(self.api_url)
      end

      set_new_realm(realm_key_id, realm_secret)

    end

    # use a new realm_key_id and realm_secret. updates the user_api handle to reflect this change as well.
    # @param [String] realm_key_id
    # @param [String] realm_secret
    # @return [TrueClass] will always return true
    def set_new_realm(realm_key_id, realm_secret)
      self.realm_key_id = realm_key_id
      self.realm_secret = realm_secret
      if user_api.is_a? ::Tozny::User
        user_api.set_new_realm(realm_key_id)
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
        login_info = JSON.parse(::Tozny::Core.base64url_decode(signed_data))
        return false if login_info[:expires_at] < Time.now.to_i
        login_info
      else
        false
      end
    end

    # verify a login from a user and session id. Does not return complete login information.
    # @param [String] user_id the user_id of the login to check
    # @param [String] session_id the session_id of the login to check
    # @return [Hash] the return from the API
    def check_login_via_api(user_id, session_id) # NOTE: this only returns true/false. You need to parse the data locally. See Tozny::Core.base64url_decode
      raw_call(
        method: 'realm.check_valid_login',
        user_id: user_id,
        session_id: session_id
      )[:return] == 'true'
    end

    # Add a user to a closed realm
    # @param [String] defer 'true' or 'false', defines whether the user should be deferred to later be completed by the app
    # @param [Hash] meta any metadata to be added to the user (eg, favorite color or mother's home address). All meta will be stored as strings
    # @param [String, OpenSSL::PKey::RSA] pub_key the public key of the user to be added. Only necessary
    # @return [Hash, FalseClass] the user in its current (incomplete if defer is 'true' state)
    # @raise ArgumentError if there is no pubkey when there should be one
    def user_add(defer = 'false', meta = nil, pub_key)
      unless pub_key.nil?
        pub_key = OpenSSL::PKey::RSA.new pub_key if pub_key.is_a? String
        pub_key = pub_key.public_key if pub_key.private?
      end

      request_obj = {
        method: 'realm.user_add',
        defer: defer
      }
      if defer == 'false'
        raise ArgumentError, 'Must provide a public key if not using deferred enrollment' if pub_key.nil?
        request_obj[:pub_key] = pub_key
      end

      unless meta.nil?
        request_obj[:extra_fields] = Tozny::Core.base64url_encode(meta.to_json)
      end

      user = raw_call request_obj
      return false unless user[:return] == 'ok'
      user
    end

    # update a user's meta fields
    # * Note: all meta fields are stored as strings
    # @param [String] user_id
    # @param [Hash{Symbol,String=>Object}] meta the metadata fields to update, along with their new values
    # @return [Hash] the updated user
    def user_update(user_id, meta)
      raw_call(
        method: 'realm.user_update',
        user_id: user_id,
        extra_fields: Tozny::Core.base64url_encode(meta.to_json)
      )
    end

    # @param [String] user_id
    # @return [Hash] the result of the request to the API
    def user_delete(user_id)
      raw_call(
        method: 'realm.user_delete',
        user_id: user_id
      )
    end

    # retrieve a user's information
    # * Note: all meta fields are stored as strings
    # @param [String] user_id the id or email (if is_id = false) of the user to get
    # @param [TrueClass, FalseClass] is_id true if looking up the user by id, false if looking up by email. defaults to true
    # @return [Hash] the user's information
    # @raise ArgumentError on failed lookup
    def user_get(user_id, is_id = true)
      request_obj = {
        method: 'realm.user_get'
      }
      if is_id
        request_obj[:user_id] = user_id
      else
        request_obj[:tozny_email] = user_id
      end

      user = raw_call(request_obj)
      if user.nil? || user[:results].nil?
        raise ArgumentError, ('No user was found for ' + (is_id ? 'id' : 'email') + ': ' + user_id + '.')
      end
      user[:results]
    end

    # performs a device add call
    # @param [String] user_id
    # @return [Hash] the result of the call: keys include  :user_id, :temp_key, :secret_enrollment_url, and :key_id
    def user_device_add(user_id)
      raw_call(
        method: 'realm.user_device_add',
        user_id: user_id
      )
    end

    # create an OOB challenge question session
    # @param [Hash<Symbol, String>, String] question either a question hash, as specified by the options, or the text of a question to be presented to the user. Required.
    # @option question [String] :question The text of the question to be presented to the user
    # @option question [String] :success The URL the user's browser should be redirected to after successful authentication
    # @option question [String] :error The URL the user's browser should be redirected to after unsuccessful authentication
    # @param [String] success_url The URL the user's browser should be redirected to after successful authentication if not specified in the question object
    # @param [String] error_url The URL the user's browser should be redirected to after unsuccessful authentication if not specified in the question object
    # @param [String] user_id optional. The user who should answer the question.
    # @raise ArgumentError on invalid question type
    # TODO: support URI objects instead of strings for success and error
    # @return [Hash] the result of the API call
    def question_challenge(question, success_url, error_url, user_id)
      raise ArgumentError, 'question must either be a string or an options hash as specified' unless (question.is_a?String) || (question.is_a?Hash)
      final_question = nil # scope final_question and prevent linting errors
      if question.is_a?Hash
        final_question = question
        final_question[:type] = 'callback'
      elsif (success_url.is_a?String) || (error_url.is_a?String)
        final_question = {
          type: 'callback',
          question: question
        }
        final_question[:success] = success_url if success_url.is_a?String
        final_question[:error] = error_url if error_url.is_a?String
      else
        final_question = {
          type: 'question',
          question: question
        }
      end
      request_obj = {
        method: 'realm.question_challenge',
        question: final_question
      }
      request_obj[:user_id] = user_id if user_id.is_a?String
      raw_call request_obj
    end

    # Create an OTP challenge session
    # @return [Hash] a hash [session_id, presence] containing an OTP session id and an OTP presence (an alias for a type-destination combination)
    # @param [String] type one of 'sms-otp-6', 'sms-otp-8': the type of the OTP to send
    # @param [String] destination the destination for the OTP. For an SMS OTP, this should be a phone number
    # @param [String] presence can be used instead of 'type' and 'destination': an OTP presence provided by the TOZNY API
    # @param [Object] data optional passthru data to be added to the signed response on a successful request
    # @raise ArgumentError when not enough information to submit an OTP request
    # @raise ArgumentError on invalid request type
    def otp_challenge(type = nil, destination = nil, presence = nil, data = nil)
      raise ArgumentError, 'must provide either a presence or a type and destination' if (type.nil? || destination.nil?) && presence.nil?
      request_obj = {
        method: 'realm.otp_challenge'
      }
      unless data.nil?
        data = data.to_json unless data.is_a?String
        request_obj[:data] = data
      end

      if presence.nil?
        raise ArgumentError, "request type must one of 'sms-otp-6' or 'sms-otp-8'" unless %w(sms-otp-6 sms-otp-8).include? type
        request_obj[:type] = type
        # TODO: consider validating that 'destination' is a valid phone number when 'type' is sms-otp-*
        request_obj[:destination] = destination
      else
        request_obj[:presence] = presence
      end
      raw_call request_obj
    end

    # Shorthand method to send an 6-digit OTP via SMS without a presence token
    # @param destination @see(otp_challenge)
    # @param data @see(otp_challenge)
    # @return @see(otp_challenge)
    def sms_otp(destination, data = nil)
      # TODO: validate that 'destination' is a phone number
      otp_challenge('sms-otp-6', destination, nil, data)
    end

    # push to a user's device based off of their id, email, or username
    # @raise ArgumentError when not enough information is provided to find the user
    # @param [String] session_id optional a valid Tozny session_id
    # @param [String] user_id optional a Tozny user_id
    # @param [String] email optional an email for a field associated with tozny_email
    # @param [String] username optional a username for a field associated with tozny_username
    # @return [Hash {Symbol => String, Integer, Array<TrueClass, FalseClass>}] the result of the push attempt. Will be true if any device owned by the user is successfully sent a push.
    def user_push(session_id = nil, user_id = nil, email = nil, username = nil)
      raise ArgumentError, 'must provide either a Tozny user id, a tozny_email, or a tozny_username in order to find the user to push to' if
          user_id.nil? && email.nil? && username.nil?
      session_id ||= user_api.login_challenge[:session_id]
      request_obj = {
        method: 'realm.user_push',
        session_id: session_id
      }
      if !user_id.nil?
        request_obj[:user_id] = user_id
      elsif !email.nil?
        request_obj[:tozny_email] = email
      elsif !username.nil?
        request_obj[:tozny_username] = username
      end
      raw_call request_obj
    end

    # perform a raw(ish) API call
    # @param [Hash{Symbol, String => Object}] request_obj The request to conduct. Should include a :method at the least. Prefer symbol keys to string keys
    # @return [Object] The parsed result of the request. NOTE: most types will be stringified for most requests
    def raw_call(request_obj)
      request_obj[:nonce] = Tozny::Core.generate_nonce # generate the nonce
      request_obj[:expires_at] = Time.now.to_i + 5 * 60 # UNIX timestamp for now +5 min TODO: does this work with check_login_via_api, or should it default to a passed in expires_at?
      unless request_obj.key?('realm_key_id') || request_obj.key?(:realm_key_id) # check for both string and symbol
        # TODO: how should we handle conflicts of symbol and string keys?
        request_obj[:realm_key_id] = realm_key_id
      end
      encoded_params = Tozny::Core.encode_and_sign(request_obj.to_json, realm_secret) # make a proper request of it.
      request_url = api_url # copy the URL to a local variable so that we can add the query params
      request_url.query = URI.encode_www_form encoded_params # encode signed_data and signature as query params
      # p request_url
      http_result = Net::HTTP.get(request_url)
      JSON.parse(http_result, symbolize_names: true) # TODO: handle errors
    end
  end
end
