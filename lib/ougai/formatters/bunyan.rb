# frozen_string_literal: true

require 'ougai/formatters/base'

module Ougai
  module Formatters
    # A JSON formatter compatible with node-bunyan
    class Bunyan < Base
      include ForJson

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
        init_opts_for_json(opts)
      end

      def _call(severity, time, progname, item)
        data = {
          name: progname || @app_name,
          hostname: @hostname,
          pid: $$,
          level: to_level(severity),
          time: time,
          v: 0
        }.merge(item.data)
        data[@msg_key] = item.msg
        data[@exc_key] = serialize_exc(item.exc) if item.exc
        dump(data)
      end

      def convert_time(data)
        data[:time] = format_datetime(data[:time])
      end
    end
  end
end
