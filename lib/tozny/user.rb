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

    def check_session_status(session_id)
      raw_call({
        :method => 'user.check_session_status',
        :session_id => session_id
      }).has_key?(:signed_data)
    end

    # use a new realm_key_id
    # @param [String] realm_key_id
    # @return [TrueClass] will always return true
    def set_new_realm (realm_key_id)
      self.realm_key_id = realm_key_id
      true
    end

    def raw_call(request_obj)
      unless request_obj.key?('realm_key_id') || request_obj.key?(:realm_key_id) #check for both string and symbol
        #TODO: how should we handle conflicts of symbol and string keys?
        request_obj[:realm_key_id] = realm_key_id
      end
      request_url = api_url #copy the URL to a local variable so that we can add the query params
      request_url.query = URI.encode_www_form request_obj #encode request as query params
      #p request_url
      JSON.parse(Net::HTTP.get(request_url), {:symbolize_names => true})
    end
  end
end