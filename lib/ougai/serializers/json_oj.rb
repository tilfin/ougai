require 'oj'

module Ougai::Serializers
  class JsonOj < Ougai::Serializer
    OJ_OPTIONS = { mode: :custom, time_format: :xmlschema,
                   use_as_json: true, use_to_hash: true, use_to_json: true }

    def serialize(data)
      Oj.dump(data, OJ_OPTIONS)
    end
  end
end
