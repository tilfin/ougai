# frozen_string_literal: true

require 'ougai/formatters/base'
require 'ougai/colors/configuration'

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
      # @option opts [Hash] :colors set of color configuration to initialize a Ougai::Colors::Configuration
      # @option opts [Ougai::Colors::Configuration] :color_config assign a color configuration. Takes
      #                                             predecence over :colors
      def initialize(app_name = nil, hostname = nil, opts = {})
        aname, hname, opts = Base.parse_new_params([app_name, hostname, opts])
        super(aname, hname, opts)
        @trace_indent = opts.fetch(:trace_indent, 4)
        @excluded_fields = opts[:excluded_fields] || []
        @serialize_backtrace = true

        # Colorization
        @plain = opts.fetch(:plain, false)
        if opts.key?(:color_config)
          @color_config = opts[:color_config]
        else
          @color_config = Ougai::Colors::Configuration.new(opts[:colors] || {})
        end

        # Customizable log part formatter
        @msg_formatter = opts.fetch(:msg_formatter) do
          MessageFormatter.new(@color_config, @plain)
        end
        @data_formatter = opts.fetch(:data_formatter) do
          DataFormatter.new(@plain)
        end
        @err_formatter = opts.fetch(:err_formatter) do
          ErrorFormatter.new(@trace_indent)
        end

        load_dependent
      end

      def _call(severity, time, progname, data)
        strs = []
        # Main message
        msg = data.delete(:msg)
        dt = format_datetime(time)
        strs << @msg_formatter.call(dt, severity, msg, progname, data)

        # Error: displayed before additional data
        if data.key?(:err)
          err = 
          err_str = @err_formatter.call(data)
          strs.push(err_str)
        end

        # Additional data
        @excluded_fields.each { |field| data.delete(field) }
        unless data.empty?
          data_str = @data_formatter.call(data)
          strs.push(data_str)
        end

        strs.join("\n") + "\n"
      end

      def serialize_backtrace=(_value)
        raise NotImplementedError, 'Not support serialize_backtrace'
      end

      protected

      def load_dependent
        require 'awesome_print'
      rescue LoadError
        puts 'You must install the awesome_print gem to use this output.'
        raise
      end

      # Message line formatting class
      class MessageFormatter
        # @param [Ougai::Colors::Configuration] color_config: Inherit color
        #        configuration from Formatter
        # @param [Boolean] plain: Inherit plain attribute from Formatter
        def initialize(color_config, plain = false)
          @color_config = color_config
          @plain = plain
        end

        # @param [String] datetime: formatted uncolored datetime
        # @param [String] severity: unformatted uncolored severity
        # @param [String] msg: main log message
        # @param [String] _progname: optional program name
        # @param [Hash] _data: additional data
        def call(datetime, severity, msg, _progname, _data)
          # optional colorization
          unless @plain
            severity = @color_config.color(:severity, severity, severity)
          end

          # Formatted output
          "[#{datetime}] #{severity}: #{msg}"
        end
      end

      # Data formatting class
      class DataFormatter
        # @param [Boolean] plain: Inherit plain attribute from Formatter
        def initialize(plain = false)
          @plain = plain
        end

        def call(data)
          data.ai(plain: @plain)
        end
      end

      # Error formatting class
      class ErrorFormatter
        # @param [Integer] trace_indent (4): Inherit trace_indent attribute from Formatter
        def initialize(trace_indent = 4)
          @trace_indent = trace_indent
        end

        # Formatting error
        def call(data)
          err = data.delete(:err)
          err_str = "  #{err[:name]} (#{err[:message]}):"
          err_str += "\n" + (' ' * @trace_indent) + err[:stack] if err.key?(:stack)
          err_str
        end
      end

    end
  end
end
