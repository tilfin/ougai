require 'ougai/formatters/base'
require 'oj'

module Ougai
  module Formatters
    # A JSON formatter compatible with node-bunyan
    # @attr [Boolean] jsonize Whether log should converts JSON
    # @attr [Boolean] with_newline Whether tailing NL should be appended
    class Bunyan < Base
      attr_accessor :jsonize, :with_newline

      # Intialize a formatter
      # @param [String] app_name application name (execution program name if nil)
      # @param [String] hostname hostname (hostname if nil)
      # @param [Hash] opts the initial values of attributes
      # @option opts [String] :trace_indent (2) the value of trace_indent attribute
      # @option opts [String] :trace_max_lines (100) the value of trace_max_lines attribute
      # @option opts [String] :serialize_backtrace (true) the value of serialize_backtrace attribute
      # @option opts [String] :jsonize (true) the value of jsonize attribute
      # @option opts [String] :with_newline (true) the value of with_newline attribute
      def initialize(app_name = nil, hostname = nil, opts = {})
        aname, hname, opts = Base.parse_new_params([app_name, hostname, opts])
        super(aname, hname, opts)
        @jsonize = opts.fetch(:jsonize, true)
        @with_newline = opts.fetch(:with_newline, true)
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

      OJ_OPTIONS = { mode: :custom, time_format: :xmlschema,
                     use_as_json: true, use_to_hash: true, use_to_json: true }

      def dump(data)
        return data unless @jsonize
        data[:time] = format_datetime(data[:time])
        str = Oj.dump(data, OJ_OPTIONS)
        str << "\n" if @with_newline
        str
      end
    end
  end
end
