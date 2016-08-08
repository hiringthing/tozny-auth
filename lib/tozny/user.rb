require 'tozny/auth/common'

module Tozny
  class User
    attr_accessor :realm_key_id, :api_url
    def initialize(realm_key_id, api_url = nil)
      if !api_url.nil?
        self.api_url = api_url
      elsif !(ENV['API_URL'].nil?) # rubocop:disable all
        self.api_url = ENV['API_URL']
      else
        self.api_url = 'https://api.tozny.com/index.php'
      end

      self.api_url = URI.parse(self.api_url) unless self.api_url.is_a? URI

      set_new_realm(realm_key_id)
    end

    # check the status of a session
    # @param [String] session_id the session to check
    # @return [TrueClass, FalseClass] 'true' if the use has logged in with the session, false otherwise
    def check_session_status(session_id)
      raw_call(
        method: 'user.check_session_status',
        session_id: session_id
      ).key?(:signed_data)
    end

    # use a new realm_key_id
    # @param [String] realm_key_id
    # @return [TrueClass] will always return true
    def set_new_realm(realm_key_id) # rubocop:disable Style/AccessorMethodName
      self.realm_key_id = realm_key_id
      true
    end

    # Generate a new login challenge session
    # @param [TrueClass, FalseClass] user_add optional: whether or not to create an enrollment challenge rather than an authentication challenge
    # @return [Hash] a challenge session (:challenge, :realm_key_id, :session_id, :qr_url, :mobile_url, :created_at, :presence = "")
    def login_challenge(user_add = nil)
      request_obj = {
        method: 'user.login_challenge'
      }
      request_obj[:user_add] = user_add if user_add
      raw_call request_obj
    end

    # Create an OTP challenge session
    # @return [Hash] a hash [session_id, presence] containing an OTP session id and an OTP presence (an alias for a type-destination combination)
    # @param [String] type one of 'sms-otp-6', 'sms-otp-8': the type of the OTP to send
    # @param [String] destination the destination for the OTP. For an SMS OTP, this should be a phone number
    # @param [String] presence can be used instead of 'type' and 'destination': an OTP presence provided by the TOZNY API
    # @raise ArgumentError when not enough information to submit an OTP request
    # @raise ArgumentError on invalid request type
    def otp_challenge(type = nil, destination = nil, presence = nil)
      raise ArgumentError, 'must provide either a presence or a type and destination' if (type.nil? || destination.nil?) && presence.nil?
      request_obj = {
        method: 'user.otp_challenge'
      }
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

    # Check an OTP against an OTP session
    # @param [String] session_id the OTP session to validate
    # @param [String, Integer] otp the OTP to check
    # @return [Hash] The signed_data and signature containing a session ID and metadata, if any, on success. Otherwise, error[s].
    def otp_result(session_id, otp)
      raw_call(method: 'user.otp_result', session_id: session_id, otp: otp)
    end

    # Verify an email-based OTP
    # @param [String] otp The OTP to validate
    # @return [Hash] If successful, this request returns a redirect to the registered callback. Otherwise it returns a JSON array.
    def email_result(otp)
      params = {
          method: 'user.email_result',
          realm_key_id: realm_key_id,
          otp: otp
      }
      raw_call(params)
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
      JSON.parse(Net::HTTP.get(request_url), symbolize_names: true)
    end
  end
end
