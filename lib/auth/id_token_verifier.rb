module Auth
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
        token_for_us? &&
        !token_expired? &&
        token_intact?
    end

    def token_for_us?
      jwt[:aud] == Auth.config.audience
    end

    def token_expired?
      jwt[:exp] < @time
    end

    def token_intact?
      jwt.verify!(@keychain.getset(jwt['iss']){ Issuer.new(jwt['iss']).signing_key })
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