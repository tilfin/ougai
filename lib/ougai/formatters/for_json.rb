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
  end
end
