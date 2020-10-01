# frozen_string_literal: true

# Tried to only use stdlib gems for a minimal footprint
require 'json'
require 'net/http'
require 'openssl'
require 'uri'

require_relative 'core_ext'
require 'keepasshttp/crypto'

# At the moment everything is in this one class as the "logic" is manageable
class Keepasshttp
  VERSION = '0.2.0'

  include Crypto
  using Base64Helper

  def self.connect(**params)
    kee = new(**params)
    kee.login
    kee
  end

  attr_accessor :port
  attr_reader :id
  autoload :Formatter, 'keepasshttp/formatter'
  autoload :KeyStore, 'keepasshttp/key_store'

  def initialize(port: 19_455, key_store: :auto)
    @port = port
    @key_store = KeyStore.init(key_store)
  end

  def credentials_for(url)
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

  def formatted_credentials_for(urls, style)
    list = urls.map do |url|
      credentials_for(url).map do |dataset|
        case style.to_s
        when 'url' then Formatter.as_url(url, dataset)
        when 'json' then dataset
        else raise ArgumentError, "Unknown output format #{style.inspect}"
        end
      end
    end.flatten
    list = list.first if list.size == 1
    list = list.to_json if style.to_s == 'json'
    list
  end

  def login
    return true if @session

    new_session
    return cached_login if @key_store&.available?

    @key = session.random_key
    new_iv

    json = http(:associate, Key: @key.to_base64)
    return false unless json

    @id = json['Id']

    @key_store&.save(id: @id, key: @key)
  end

  def cached_login
    cache = @key_store.load
    @key = cache[:key]
    @id = cache[:id]
    new_iv
    ping
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
end
