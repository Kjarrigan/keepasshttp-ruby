# frozen_string_literal: true

require 'yaml'

class Keepasshttp
  # Manage keepasshttp credentials by storing them in various places to reuse
  # them and prevent popping up keepass dialogs
  module KeyStore
    using Base64Helper

    def self.list
      constants.sort.map do |name|
        klass = const_get(name)
        next nil unless klass.is_a?(Class)

        klass
      end.compact
    end

    def self.init(type)
      case type
      when Hash, String then External.new(key_store)
      when false then nil
      when :auto
        use = list.find(&:available?)
        use ||= Environment
        use
      else KeyStore.const_get(type)
      end
    rescue StandardError
      raise ArgumentError, "Invalid key_store #{type.inspect}"
    end

    # Input the key and the id directly into the client so you can take care
    # of the storage yourself.
    class External
      def initialize(token = nil, key: nil, id: nil)
        if token && key
          raise ArgumentError, 'Either provide a ID:KEY string or a hash, not' \
                               ' both'
        end
        key, id = string.split(':') if token.is_a?(String)

        @params = { key: key, id: id }
      end

      def save(*_args)
        false
      end

      def load
        @params
      end

      def available?
        true
      end

      def self.available?
        false
      end
    end

    # Read id and key from the KEEPASSHTTP_TOKEN environment variable
    # you can even use this to store the values but this obviously only
    # survives within the running ruby process
    class Environment
      class << self
        def load
          id, key = ENV['KEEPASSHTTP_TOKEN'].split(':')
          { key: key.from_base64, id: id }
        end

        def save(id:, key:, **_params)
          ENV['KEEPASSHTTP_TOKEN'] = [id, key.to_base64].join(':')
        end

        def available?
          !ENV['KEEPASSHTTP_TOKEN'].nil?
        end
      end
    end

    # The most simple but unsecure way wo store your session key (so you don't
    # have to reenter the label over and over again). Use this only for testing!
    class Plain
      # TODO, make the PATH adjustable
      PATH = File.join(Dir.home, '.config', 'keepasshttp-ruby')
      def self.save(params = {})
        File.write(PATH, params.to_yaml)
      end

      def self.load
        YAML.load_file(PATH)
      end

      def self.available?
        File.exist?(PATH) && File.size(PATH).positive?
      end
    end

    # Use your running ssh-agent session to encrypt your session key
    class SshAgent < Plain
      class << self
        def available?
          require 'net/ssh'

          super && File.read(Plain::PATH).match?(/iv:/)
        rescue LoadError
          raise LoadError, 'To use key_store: :SshAgent you have to install ' \
                           "the 'net-ssh' gem"
        end

        def save(params = {})
          enc, iv = encrypt(params.delete(:key))
          params[:key] = enc
          params[:iv] = iv
          super(params)
        end

        def load
          params = super
          params[:key] = decrypt(params[:key], iv: params.delete(:iv))
          params
        end

        private

        def encrypt(string)
          agent = Net::SSH::Authentication::Agent.connect

          cip = OpenSSL::Cipher.new('AES-256-CBC')
          cip.encrypt
          iv = cip.random_iv

          cip.key = agent.sign(identity(agent), iv)[-32..-1]

          [cip.update(string) + cip.final, iv]
        end

        def decrypt(string, iv:)
          agent = Net::SSH::Authentication::Agent.connect

          cip = OpenSSL::Cipher.new('AES-256-CBC')
          cip.decrypt
          cip.iv = iv

          cip.key = agent.sign(identity(agent), iv)[-32..-1]

          cip.update(string) + cip.final
        end

        # TODO, make the key selectable
        def identity(agent)
          if agent.identities.empty?
            raise 'No identity available. Run `ssh-add` and try again'
          end

          agent.identities.first
        end
      end
    end
  end
end
