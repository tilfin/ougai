require 'logger'
require 'time'
require 'socket'

module Ougai
  module Formatters
    class Base < Logger::Formatter
      attr_accessor :trace_indent, :trace_max_lines

      def initialize(app_name = nil, hostname = nil)
        @app_name = app_name || File.basename($0, ".rb")
        @hostname = hostname || Socket.gethostname
        @trace_indent = 2
        @trace_max_lines = 100
      end

      def serialize_exc(ex)
        err = {
          name: ex.class.name,
          message: ex.to_s
        }
        if ex.backtrace
          err[:stack] = serialize_trace(ex.backtrace)
        end
        err
      end

      def serialize_trace(trace)
        sp = "\n" + ' ' * @trace_indent
        trace.slice(0, @trace_max_lines).join(sp)
      end
    end
  end
end
