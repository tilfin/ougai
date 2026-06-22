# frozen_string_literal: true

require 'json'

module Ougai::Serializers
  class Json < Ougai::Serializer
    def serialize(data)
      JSON.generate(data)
    end
  end
end
