# frozen_string_literal: true

module Ougai
  # Main Logger
  # @attr [String] default_message Use this if log message is not specified (by default this is 'No message').
  # @attr [Hash] with_fields The fields appending to all logs.
  # @attr [Proc] before_log Hook before logging.
  class Logger < ::Logger
    include Logging

    attr_accessor :default_message

    def initialize(*args)
      super(*args)
      @before_log = nil
      @default_message = 'No message'
      @with_fields = {}
      @formatter = create_formatter if @formatter.nil?
    end

    class << self
      def child_class
        @child_class ||= ChildLogger
      end

      def child_class=(klass)
        @child_class = klass
      end

      def inherited(subclass)
        subclass.child_class = Class.new(ChildLogger)
      end
    end

    # Broadcasts the same logs to the another logger
    # @param logger [Logger] The logger receiving broadcast logs.
    def self.broadcast(logger)
      Module.new do |mdl|
        define_method(:log) do |*args|
          logger.log(*args)
          super(*args)
        end

        define_method(:level=) do |level|
          logger.level = level
          super(level)
        end

        define_method(:close) do
          logger.close
          super()
        end
      end
    end

    def level=(severity)
      if severity.is_a?(Integer)
        @level = severity
        return
      end

      if severity.to_s.downcase == 'trace'
        @level = TRACE
        return
      end

      super
    end

    # Creates a child logger and returns it.
    # @param fields [Hash] The fields appending to all logs
    # @return [ChildLogger] A created child logger
    def child(fields = {})
      ch = self.class.child_class.new(self, fields)

      if !block_given?
        ch
      else
        yield ch
      end
    end

    # @private
    def chain(severity, args, fields, hooks)
      hooks.push(@before_log) if @before_log
      write(severity, args, weak_merge!(fields, @with_fields), hooks)
    end

    protected

    # @private
    def append(severity, args)
      hooks = @before_log ? [@before_log] : []
      write(severity, args, @with_fields, hooks)
    end

    def create_formatter
      Formatters::Bunyan.new
    end

    private

    def format_severity(severity)
      to_label(severity)
    end

    def write(severity, args, fields, hooks)
      item = to_item(args)
      weak_merge!(item.data, fields)
      hooks.each do |hook|
        return false if hook.call(item) == false
      end
      add(severity, item)
    end

    def to_item(args)
      Ougai::LogItem.new(@default_message, args)
    end
  end
end
