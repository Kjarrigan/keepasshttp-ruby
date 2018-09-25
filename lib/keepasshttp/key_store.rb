# frozen_string_literal: true

require 'yaml'

class Keepasshttp
  module KeyStore
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
  end
end
