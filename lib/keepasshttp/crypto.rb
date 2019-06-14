# frozen_string_literal: true

using Base64Helper

class Keepasshttp
  # There is a minimal crypto setup necessary for keepass
  module Crypto
    attr_reader :session
    def new_session
      @session = OpenSSL::Cipher.new('AES-256-CBC')
      session.encrypt
    end

    def new_iv
      iv = session.random_iv
      @nonce = iv.to_base64
      @verifier = encrypt(iv.to_base64, iv: iv)
      iv
    end

    def encrypt(val, iv:)
      session.encrypt
      session.key = @key
      session.iv = iv

      (session.update(val) + session.final).to_base64
    end

    def decrypt(string, iv:)
      session.decrypt
      session.key = @key
      session.iv = iv.unpack1('m*')

      session.update(string.unpack1('m*')) + session.final
    end
  end
end
