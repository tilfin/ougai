# frozen_string_literal: true

require 'time'
require 'socket'

module Ougai
  module Formatters
    # Base formatter
    # Custom formatter must override `_call`.
    # @attr [Fixnum] trace_indent Specify exception backtrace indent (by default this is 2).
    # @attr [Fixnum] trace_max_lines Keep exception backtrace lines (by default this is 100).
    # @attr [Boolean] serialize_backtrace Whether exception should converts String (by default this is on).
    class Base < Logger::Formatter
      attr_accessor :trace_indent, :trace_max_lines
      attr_accessor :serialize_backtrace
      attr_reader :app_name, :hostname

      # Intialize a formatter
      # @param [String] app_name application name
      # @param [String] hostname hostname
      # @param [Hash] opts the initial values of attributes
      # @option opts [String] :trace_indent (2) the value of trace_indent attribute
      # @option opts [String] :trace_max_lines (100) the value of trace_max_lines attribute
      # @option opts [String] :serialize_backtrace (true) the value of serialize_backtrace attribute
      def initialize(app_name = nil, hostname = nil, opts = {})
        @app_name = app_name || File.basename($0, ".rb")
        @hostname = hostname || Socket.gethostname.force_encoding('UTF-8')
        @trace_indent = opts.fetch(:trace_indent, 2)
        @trace_max_lines = opts.fetch(:trace_max_lines, 100)
        @serialize_backtrace = opts.fetch(:serialize_backtrace, true)
        self.datetime_format = nil
      end

      def call(severity, time, progname, data)
        _call(severity, time, progname, data.is_a?(Hash) ? data : { msg: data.to_s })
      end

      def _call(severity, time, progname, data)
        raise NotImplementedError, "_call must be implemented"
      end

      def datetime_format=(value)
        @datetime_format = value || default_datetime_format
      end

      def serialize_exc(ex)
        err = {
          name: ex.class.name,
          message: ex.to_s
        }
        if ex.backtrace
          bt = ex.backtrace.slice(0, @trace_max_lines)
          err[:stack] = @serialize_backtrace ? serialize_trace(bt) : bt
        end
        err
      end

      def serialize_trace(trace)
        sp = "\n" + ' ' * @trace_indent
        trace.join(sp)
      end

      private

      def format_datetime(time)
        time.strftime(@datetime_format)
      end

      def default_datetime_format
        "%FT%T.%3N#{(Time.new.utc? ? 'Z' : '%:z')}"
      end

      def self.parse_new_params(args)
        idx = args.index {|i| i.is_a?(Hash) }
        return args if idx == 2
        opts = args[idx]
        app_name = opts.delete(:app_name)
        hostname = opts.delete(:hostname)
        app_name ||= args[0] if idx > 0
        [app_name, hostname, opts]
      end
    end
  end
end
