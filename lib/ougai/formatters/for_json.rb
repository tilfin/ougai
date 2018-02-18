require 'oj'

module Ougai
  # The features for JSON
  module Formatters::ForJson
    def to_level(severity)
      case severity
      when 'TRACE'
        10
      when 'DEBUG'
        20
      when 'INFO'
        30
      when 'WARN'
        40
      when 'ERROR'
        50
      when 'FATAL'
        60
      else
        70
      end
    end

    OJ_OPTIONS = { mode: :custom, time_format: :xmlschema,
                   use_as_json: true, use_to_hash: true, use_to_json: true }

    # requires convert_time(data) method
    def dump(data)
      return data unless @jsonize
      convert_time(data)
      str = Oj.dump(data, OJ_OPTIONS)
      str << "\n" if @with_newline
      str
    end
  end
end
