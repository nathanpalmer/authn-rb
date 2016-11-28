require 'net/http'

module Keratin::AuthN
  class Issuer
    def initialize(str)
      @uri = str
      @config_uri = @uri.chomp('/') + Keratin::AuthN.config.configuration_path
    end

    def signing_key
      keys.find{|k| k['use'] == 'sig' }
    end

    def configuration
      @configuration ||= JSON.parse(
        Net::HTTP.get(URI.parse(@config_uri))
      )
    end

    def keys
      @keys ||= JSON::JWK::Set.new(
        JSON.parse(
          Net::HTTP.get(URI.parse(configuration['jwks_uri']))
        )
      )
    end
  end
end
