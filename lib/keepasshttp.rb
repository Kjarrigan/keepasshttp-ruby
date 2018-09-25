# frozen_string_literal: true

# Tried to only use stdlib gems for a minimal footprint
require 'json'
require 'net/http'
require 'openssl'

# At the moment everything is in this one class as the "logic" is manageable
class Keepasshttp
  # Provide String.to_base64 as refinement
  module Base64Helper
    refine String do
      def to_base64
        [self].pack('m*').chomp
      end
    end
  end
  using Base64Helper

  VERSION = '0.1.0'

  def self.connect(port: 19_455)
    kee = new(port: port)
    kee.login
    kee
  end

  attr_accessor :port
  attr_reader :session

  def initialize(port: 19_455)
    @port = port
    @session = false
  end

  def password_for(url)
    ping

    enc_url = encrypt(url, iv: new_iv)
    json = http('get-logins', Url: enc_url)
    iv = json['Nonce']
    json['Entries'].map do |dataset|
      dataset.map do |key, val|
        [key, decrypt(val, iv: iv)]
      end.to_h
    end
  end

  def login
    return true if @session

    @session = OpenSSL::Cipher.new('AES-256-CBC')
    session.encrypt
    @key = session.random_key
    new_iv

    json = http(:associate, Key: @key.to_base64)
    return false unless json

    @id = json['Id']
  end

  def ping
    http 'test-associate'
  end

  private

  def http(request_type, params = {})
    params = { RequestType: request_type, TriggerUnlock: false }.merge(params)
    params[:Id] ||= @id if @id
    params[:Verifier] ||= @verifier if @verifier
    params[:Nonce] ||= @nonce if @nonce

    success?(
      Net::HTTP.post(URI("http://localhost:#{port}/"), params.to_json,
                     'Content-Type' => 'application/json')
    )
  end

  def success?(resp)
    json = JSON.parse(resp.body)
    return json if resp.code =~ /^2..$/ && json['Success']

    raise(json['Error'] || resp.body)
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
