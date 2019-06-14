# frozen_string_literal: true

class Keepasshttp
  # to add more use-cases for the cli provide some output formats so
  # you can do stuff like:
  #    ssh $(Keepasshttp example.com --format url)
  module Formatter
    def self.as_url(url, dataset)
      url = URI(url)
      url.user = dataset['Login']
      url.password = dataset['Password']
      url.to_s
    end
  end
end
