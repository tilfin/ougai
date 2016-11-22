require 'ougai/formatters/base'

module Ougai
  module Formatters
    class Readable < Base
      attr_accessor :plain, :trace_indent

      def initialize(opts = {})
        super(opts[:app_name], opts[:hostname])
        @trace_indent = opts[:trace_indent] || 4
        @plain = opts[:plain] || false
        load_awesome_print
      end

      def call(severity, time, progname, data)
        msg = data.delete(:msg)
        level = @plain ? severity : colored_level(severity)
        strs = ["[#{time.iso8601(3)}] #{level}: #{msg}"]
        if data.key?(:err)
          err = data.delete(:err)
          err_str = "  #{err[:name]} (#{err[:message]}):"
          err_str += "\n    " + err[:stack] if err.key?(:stack)
          strs.push(err_str)
        end
        unless data.empty?
          strs.push(data.ai({ plain: @plain }))
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

      def load_awesome_print
        require 'awesome_print'
      rescue LoadError
        puts 'You must install the awesome_print gem to use this output.'
        raise
      end
    end
  end
end
