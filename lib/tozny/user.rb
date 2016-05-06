require "tozny/auth/common"

module Tozny
  class User
    attr_accessor :realm_key_id, :api_url
    def initialize(realm_key_id, api_url = nil)
      self.set_new_realm(realm_key_id)
      if !api_url.nil?
        self.api_url = api_url
      elsif !(ENV['API_URL'].nil?)
        self.api_url=ENV['API_URL']
      else
        self.api_url='https://api.tozny.com/index.php'
      end
      self.api_url = URI.parse(self.api_url)

    end

    def set_new_realm (realm_key_id)
      self.realm_key_id = realm_key_id
    end
    def raw_call(request_obj)
      #TODO implement
    end
  end
end