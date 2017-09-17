module Ougai
  # Main Logger
  # @attr [String] default_message Use this if log message is not specified (by default this is 'No message').
  # @attr [String] exc_key The field name of Exception (by default this is :err).
  # @attr [Hash] with_fields The fields appending to all logs.
  # @attr [Proc] before_log Hook before logging.
  class Logger < ::Logger
    include Logging

    attr_accessor :default_message, :exc_key

    def initialize(*args)
      super(*args)
      @default_message = 'No message'
      @exc_key = :err
      @with_fields = {}
      @formatter = create_formatter
    end

    # Broadcasts the same logs to the another logger
    # @param logger [Logger] The logger receiving broadcast logs.
    def self.broadcast(logger)
      Module.new do |mdl|
        Logger::Severity.constants.each do |severity|
          method_name = severity.downcase.to_sym

          mdl.send(:define_method, method_name) do |*args|
            logger.send(method_name, *args)
            super(*args)
          end
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

    # @private
    def chain(severity, args, fields, hooks)
      hooks.push(@before_log) if @before_log
      write(severity, args, merge_fields(@with_fields, fields), hooks)
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
      data = merge_fields(fields, to_item(args))
      hooks.each do |hook|
        return false if hook.call(data) == false
      end
      add(severity, data)
    end

    def to_item(args)
      msg, ex, data = args

      if ex.nil?
        create_item_with_1arg(msg)
      elsif data.nil?
        create_item_with_2args(msg, ex)
      elsif msg
        create_item_with_3args(msg, ex, data)
      else # No args
        { msg: @default_message }
      end
    end

    def create_item_with_1arg(msg)
      item = {}
      if msg.is_a?(Exception)
        item[:msg] = msg.to_s
        set_exc(item, msg)
      elsif msg.is_a?(Hash)
        item[:msg] = @default_message unless msg.key?(:msg)
        item.merge!(msg)
      else
        item[:msg] = msg.to_s
      end
      item
    end

    def create_item_with_2args(msg, ex)
      item = {}
      if ex.is_a?(Exception)
        item[:msg] = msg.to_s
        set_exc(item, ex)
      elsif ex.is_a?(Hash)
        item.merge!(ex)
        if msg.is_a?(Exception)
          set_exc(item, msg)
        else
          item[:msg] = msg.to_s
        end
      end
      item
    end

    def create_item_with_3args(msg, ex, data)
      item = {}
      set_exc(item, ex) if ex.is_a?(Exception)
      item.merge!(data) if data.is_a?(Hash)
      item[:msg] = msg.to_s
      item
    end

    def set_exc(item, exc)
      item[@exc_key] = @formatter.serialize_exc(exc)
    end
  end
end
