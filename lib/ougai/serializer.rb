# frozen_string_literal: true

module Ougai
  class Serializer
    def self.for_json
      if RUBY_PLATFORM =~ /java/
        require 'ougai/serializers/json_jr_jackson'
        Serializers::JsonJrJackson.new
      else
        require 'ougai/serializers/json'
        Serializers::Json.new
      end
    end
  end
end
