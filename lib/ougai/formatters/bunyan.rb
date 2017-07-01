require 'ougai/formatters/base'
require 'json'

module Ougai
  module Formatters
    class Bunyan < Base
      def call(severity, time, progname, data)
        JSON.generate({
          name: progname || @app_name,
          hostname: @hostname,
          pid: $$,
          level: to_level(severity),
          time: time.iso8601(3),
          v: 0
        }.merge(data)) + "\n"
      end

      def to_level(severity)
        case severity
        when 'INFO'
          30
        when 'WARN'
          40
        when 'ERROR'
          50
        when 'FATAL'
          60
        when 'ANY'
          70
        else # DEBUG
          20
        end
      end
    end
  end
end
