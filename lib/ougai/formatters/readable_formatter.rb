require 'ougai/formatters/base'

module Ougai
  module Formatters
    class ReadableFormatter < Base
      def initialize(app_name = nil, hostname = nil)
        super(app_name, hostname)
        @trace_indent = 4
        load_dependency
      end

      def call(severity, time, progname, data)
        msg = data.delete(:msg)
        strs = ["[#{time.iso8601(3)}] #{colored_level(severity)}: #{msg}"]
        if data.key?(:err)
          err = data.delete(:err)
          err_str = "  #{err[:name]} (#{err[:message]}):"
          err_str += "\n    " + err[:stack] if err.key?(:stack)
          strs.push(err_str)
        end
        unless data.empty?
          strs.push(data.ai)
        end
        strs.join("\n") + "\n"
      end

      def colored_level(severity)
        case severity
        when 'INFO'
          color = '0;36'
        when 'WARN'
          color = '0;33'
        when 'ERROR'
          color = '0;31'
        when 'FATAL'
          color = '0;35'
        else # DEBUG
          color = '0;37'
        end
        "\e[#{color}m#{severity}\e[0m"
      end

      private

      def load_dependency
        require 'awesome_print'
      rescue LoadError
        puts 'You must install the awesome_print gem to use this output.'
        raise
      end
    end
  end
end
