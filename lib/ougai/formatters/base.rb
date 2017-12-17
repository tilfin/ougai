require 'time'
require 'socket'

module Ougai
  module Formatters
    # Base formatter
    # @attr [Fixnum] trace_indent Specify exception backtrace indent (by default this is 2).
    # @attr [Fixnum] trace_max_lines Keep exception backtrace lines (by default this is 100).
    # @attr [Boolean] serialize_backtrace Whether exception should converts String (by default this is on).
    class Base < Logger::Formatter
      attr_accessor :trace_indent, :trace_max_lines
      attr_accessor :serialize_backtrace
      attr_reader :app_name, :hostname

      def initialize(app_name = nil, hostname = nil)
        @app_name = app_name || File.basename($0, ".rb")
        @hostname = hostname || Socket.gethostname.force_encoding('UTF-8')
        @trace_indent = 2
        @trace_max_lines = 100
        @serialize_backtrace = true
        self.datetime_format = nil
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
        t = Time.new
        f = '%FT%T.%3N'
        f << (t.utc? ? 'Z' : '%:z')
        f.freeze
      end
    end
  end
end
