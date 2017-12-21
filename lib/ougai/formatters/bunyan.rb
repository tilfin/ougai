require 'ougai/formatters/base'
require 'json'

module Ougai
  module Formatters
    # A JSON formatter compatible with node-bunyan
    # @attr [Boolean] jsonize Whether log should converts JSON (by default this is on).
    # @attr [Boolean] with_newline Whether tailing NL should be appended (by default this is on).
    class Bunyan < Base
      attr_accessor :jsonize, :with_newline

      def initialize(*args)
        super(*args)
        @jsonize = true
        @with_newline = true
      end

      def _call(severity, time, progname, data)
        dump({
          name: progname || @app_name,
          hostname: @hostname,
          pid: $$,
          level: to_level(severity),
          time: time,
          v: 0
        }.merge(data))
      end

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

      private

      def dump(data)
        return data unless @jsonize
        data[:time] = format_datetime(data[:time])
        str = JSON.generate(data)
        str << "\n" if @with_newline
        str
      end
    end
  end
end
