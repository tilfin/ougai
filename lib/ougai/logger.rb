require 'ougai/formatters/bunyan'
require 'logger'

module Ougai
  class Logger < ::Logger
    attr_accessor :default_message, :exc_key, :with_fields

    def initialize(*args)
      super(*args)
      @default_message = 'No message'
      @exc_key = :err
      @formatter = create_formatter
      @with_fields = {}
    end

    def debug(message = nil, ex = nil, data = nil, &block)
      return true if level > DEBUG
      args = block ? yield : [message, ex, data]
      add(DEBUG, build_log(args))
    end

    def info(message = nil, ex = nil, data = nil, &block)
      return true if level > INFO
      args = block ? yield : [message, ex, data]
      add(INFO, build_log(args))
    end

    def warn(message = nil, ex = nil, data = nil, &block)
      return true if level > WARN
      args = block ? yield : [message, ex, data]
      add(WARN, build_log(args))
    end

    def error(message = nil, ex = nil, data = nil, &block)
      return true if level > ERROR
      args = block ? yield : [message, ex, data]
      add(ERROR, build_log(args))
    end

    def fatal(message = nil, ex = nil, data = nil, &block)
      return true if level > FATAL
      args = block ? yield : [message, ex, data]
      add(FATAL, build_log(args))
    end

    def unknown(message = nil, ex = nil, data = nil, &block)
      args = block ? yield : [message, ex, data]
      add(UNKNOWN, build_log(args))
    end

    def self.broadcast(logger)
      Module.new do |mdl|
        ::Logger::Severity.constants.each do |severity|
          method_name = severity.downcase.to_sym

          mdl.send(:define_method, method_name) do |*args|
            logger.send(method_name, *args)
            super(*args)
          end
        end
      end
    end

    protected

    def create_formatter
      Formatters::Bunyan.new
    end

    private

    def build_log(args)
      @with_fields.merge(to_item(args))
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
