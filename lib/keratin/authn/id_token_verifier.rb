require 'uri'

module Keratin::AuthN
  class IDTokenVerifier
    def initialize(str, keychain)
      @id_token = str
      @keychain = keychain
      @time = Time.now.to_i
    end

    def subject
      jwt['sub']
    end

    def verified?
      jwt.present? &&
        token_from_us? &&
        token_for_us? &&
        !token_expired? &&
        token_intact?
    end

    def token_from_us?
      # the server or client may be configured with an extra trailing slash, unnecessary port number,
      # or something else that is an equivalent URI but not an equivalent string.
      URI.parse(jwt[:iss]) == URI.parse(Keratin::AuthN.config.issuer)
    end

    def token_for_us?
      jwt[:aud] == Keratin::AuthN.config.audience
    end

    def token_expired?
      jwt[:exp] < @time
    end

    def token_intact?
      jwt.verify!(@keychain.getset(jwt.kid){ Issuer.new(jwt['iss']).signing_key(jwt.kid) })
    rescue JSON::JWT::VerificationFailed, JSON::JWT::UnexpectedAlgorithm
      false
    end

    private def jwt
      return @jwt if defined? @jwt
      @jwt = JSON::JWT.decode(@id_token || '', :skip_verification)
    rescue JSON::JWT::InvalidFormat
      @jwt = nil
    end
  end
end
