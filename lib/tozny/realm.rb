require "tozny/auth/common"

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
    end

    def set_new_realm (realm_key_id, realm_secret)
      self.realm_key_id = realm_key_id
      self.realm_secret = realm_secret
    end
  end
end