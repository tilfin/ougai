# frozen_string_literal: true

require 'ougai/formatters/base'

module Ougai
  module Formatters
    # A JSON formatter compatible with pino
    class Pino < Base
      include ForJson

      # Intialize a formatter
      # @param [String] app_name application name (execution program name if nil)
      # @param [String] hostname hostname (hostname if nil)
      # @param [Hash] opts the initial values of attributes
      # @option opts [String] :trace_indent (4) the value of trace_indent attribute
      # @option opts [String] :trace_max_lines (100) the value of trace_max_lines attribute
      # @option opts [String] :serialize_backtrace (true) the value of serialize_backtrace attribute
      # @option opts [String] :jsonize (true) the value of jsonize attribute
      # @option opts [String] :with_newline (true) the value of with_newline attribute
      def initialize(app_name = nil, hostname = nil, opts = {})
        aname, hname, opts = Base.parse_new_params([app_name, hostname, opts])
        super(aname, hname, opts)
        init_opts_for_json(opts)
        @trace_indent = opts.fetch(:trace_indent, 4)
        @serialize_backtrace = true
      end

      def datetime_format=(val)
        raise NotImplementedError, 'Not support datetime_format attribute' unless val.nil?
      end

      def _call(severity, time, progname, data)
        flat_err(data)
        dump({
          name: progname || @app_name,
          hostname: @hostname,
          pid: $$,
          level: to_level(severity),
          time: time,
          v: 1
        }.merge(data))
      end

      def flat_err(data)
        return unless data.key?(:err)
        err = data.delete(:err)
        msg = err[:message]
        data[:type] ||= 'Error'
        data[:msg] ||= msg
        stack = "#{err[:name]}: #{msg}"
        stack += "\n" + (" " * @trace_indent) + err[:stack] if err.key?(:stack)
        data[:stack] ||= stack
      end

      def convert_time(data)
        data[:time] = (data[:time].to_f * 1000).to_i
      end
    end
  end
end
