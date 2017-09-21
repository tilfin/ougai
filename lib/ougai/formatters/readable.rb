require 'ougai/formatters/base'

module Ougai
  module Formatters
    # A human readble formatter with awesome_print
    # @attr [Boolean] plain Whether log should be plain not colorized (by default this is off).
    # @attr [Fixnum] trace_indent The indent space size (by default this is 4).
    # @attr [Array<String, Symbol>] excluded_fields The fields excluded from all logs.
    class Readable < Base
      attr_accessor :plain, :trace_indent, :excluded_fields

      def initialize(opts = {})
        super(opts[:app_name], opts[:hostname])
        @trace_indent = opts[:trace_indent] || 4
        @plain = opts[:plain] || false
        @excluded_fields = opts[:excluded_fields] || []
        load_dependent
      end

      def call(severity, time, progname, data)
        msg = data.delete(:msg)
        level = @plain ? severity : colored_level(severity)
        dt = format_datetime(time)
        err_str = create_err_str(data)

        @excluded_fields.each { |f| data.delete(f) }
        data_str = create_data_str(data)
        format_log_parts(dt, level, msg, err_str, data_str)
      end

      protected

      def format_log_parts(datetime, level, msg, err, data)
        strs = ["[#{datetime}] #{level}: #{msg}"]
        strs.push(err) if err
        strs.push(data) if data
        strs.join("\n") + "\n"
      end

      def colored_level(severity)
        case severity
        when 'TRACE'
          color = '0;34'
        when 'DEBUG'
          color = '0;37'
        when 'INFO'
          color = '0;36'
        when 'WARN'
          color = '0;33'
        when 'ERROR'
          color = '0;31'
        when 'FATAL'
          color = '0;35'
        else
          color = '0;32'
        end
        "\e[#{color}m#{severity}\e[0m"
      end

      def create_err_str(data)
        return nil unless data.key?(:err)
        err = data.delete(:err)
        err_str = "  #{err[:name]} (#{err[:message]}):"
        err_str += "\n    " + err[:stack] if err.key?(:stack)
        err_str
      end

      def create_data_str(data)
        return nil if data.empty?
        data.ai({ plain: @plain })
      end

      def load_dependent
        require 'awesome_print'
      rescue LoadError
        puts 'You must install the awesome_print gem to use this output.'
        raise
      end
    end
  end
end
