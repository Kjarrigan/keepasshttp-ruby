# frozen_string_literal: true

require 'yaml'

class Keepasshttp
  module KeyStore
    # Input the key and the id directly into the client so you can take care
    # of the storage yourself.
    class External
      def initialize(key:, id:)
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
    end

    # The most simple but unsecure way wo store your session key (so you don't
    # have to reenter the label over and over again). Use this only for testing!
    class Plain
      # TODO, make the PATH adjustable
      PATH = File.join(Dir.home, '.keepasshttp-ruby')
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

          super
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
