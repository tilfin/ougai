# frozen_string_literal: true

require 'jrjackson'

module Ougai::Serializers
  class JsonJrJackson < Ougai::Serializer
    def serialize(data)
      JrJackson::Json.dump(data)
    end
  end
end
