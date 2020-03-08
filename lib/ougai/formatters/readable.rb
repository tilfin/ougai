# frozen_string_literal: true

require 'ougai/formatters/base'

module Ougai
  module Formatters
    # A human readble formatter with awesome_print
    # @attr [Boolean] plain Whether log should be plain not colorized.
    # @attr [Array<String, Symbol>] excluded_fields The fields excluded from all logs
    class Readable < Base
      attr_accessor :plain, :excluded_fields

      # Intialize a formatter
      # @param [String] app_name application name (execution program name if nil)
      # @param [String] hostname hostname (hostname if nil)
      # @param [Hash] opts the initial values of attributes
      # @option opts [String] :trace_indent (4) the value of trace_indent attribute
      # @option opts [String] :trace_max_lines (100) the value of trace_max_lines attribute
      # @option opts [String] :plain (false) the value of plain attribute
      # @option opts [String] :excluded_fields ([]) the value of excluded_fields attribute
      def initialize(app_name = nil, hostname = nil, opts = {})
        aname, hname, opts = Base.parse_new_params([app_name, hostname, opts])
        super(aname, hname, opts)
        @trace_indent = opts.fetch(:trace_indent, 4)
        @plain = opts.fetch(:plain, false)
        @excluded_fields = opts[:excluded_fields] || []
        @serialize_backtrace = true
        load_dependent
      end

      def _call(severity, time, progname, item)
        data = item.data
        level = @plain ? severity : colored_level(severity)
        dt = format_datetime(time)
        err_str = create_err_str(serialize_exc(item.exc)) if item.exc

        @excluded_fields.each { |f| data.delete(f) }
        data_str = create_data_str(data)
        format_log_parts(dt, level, item.msg, err_str, data_str)
      end

      def serialize_backtrace=(value)
        raise NotImplementedError, 'Not support serialize_backtrace'
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

      def create_err_str(err)
        return nil unless err
        err_str = "  #{err[:name]} (#{err[:message]}):"
        err_str += "\n" + (" " * @trace_indent) + err[:stack] if err.key?(:stack)
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
