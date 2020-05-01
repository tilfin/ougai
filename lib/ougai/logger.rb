# frozen_string_literal: true

module Ougai
  # Main Logger
  # @attr [String] default_message Use this if log message is not specified (by default this is 'No message').
  # @attr [String] exc_key The field name of Exception (by default this is :err).
  # @attr [Hash] with_fields The fields appending to all logs.
  # @attr [Proc] before_log Hook before logging.
  class Logger < ::Logger
    include Logging

    attr_accessor :default_message, :exc_key

    def initialize(*, **)
      super
      @before_log = nil
      @default_message = 'No message'
      @exc_key = :err
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
      data = weak_merge!(to_item(args), fields)
      hooks.each do |hook|
        return false if hook.call(data) == false
      end
      add(severity, data)
    end

    def to_item(args)
      msg, ex, data = args

      if msg.nil?
        { msg: @default_message }
      elsif ex.nil?
        create_item_with_1arg(msg)
      elsif data.nil?
        create_item_with_2args(msg, ex)
      else
        create_item_with_3args(msg, ex, data)
      end
    end

    def create_item_with_1arg(arg)
      item = {}
      if arg.is_a?(Exception)
        item[:msg] = arg.to_s
        set_exc(item, arg)
      elsif arg.is_a?(String)
        item[:msg] = arg
      else
        item.merge!(as_hash(arg))
        item[:msg] ||= @default_message
      end
      item
    end

    def create_item_with_2args(arg1, arg2)
      item = {}
      if arg2.is_a?(Exception) # msg, ex
        item[:msg] = arg1.to_s
        set_exc(item, arg2)
      elsif arg1.is_a?(Exception) # ex, data
        set_exc(item, arg1)
        item.merge!(as_hash(arg2))
        item[:msg] ||= arg1.to_s
      else # msg, data
        item[:msg] = arg1.to_s
        item.merge!(as_hash(arg2))
      end
      item
    end

    def create_item_with_3args(msg, ex, data)
      {}.tap do |item|
        set_exc(item, ex) if ex.is_a?(Exception)
        item.merge!(as_hash(data))
        item[:msg] = msg.to_s
      end
    end

    def set_exc(item, exc)
      item[@exc_key] = @formatter.serialize_exc(exc)
    end

    def as_hash(data)
      if data.is_a?(Hash) || data.respond_to?(:to_hash)
        data
      else
        { data: data }
      end
    end
  end
end
