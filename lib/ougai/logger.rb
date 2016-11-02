require 'ougai/formatters/bunyan'
require 'logger'

module Ougai
  class Logger < ::Logger
    attr_accessor :default_message, :exc_key

    def initialize(*args)
      super(*args)
      @default_message = 'No message'
      @exc_key = :err
      @formatter = create_formatter
    end

    def debug(message, ex = nil, data = nil)
      super(to_item(message, ex, data))
    end

    def info(message, ex = nil, data = nil)
      super(to_item(message, ex, data))
    end

    def warn(message, ex = nil, data = nil)
      super(to_item(message, ex, data))
    end

    def error(message, ex = nil, data = nil)
      super(to_item(message, ex, data))
    end

    def fatal(message, ex = nil, data = nil)
      super(to_item(message, ex, data))
    end

    protected

    def create_formatter
      Formatters::Bunyan.new
    end

    private

    def to_item(msg, ex, data)
      item = {}
      if ex.nil?       # 1 arg
        if msg.is_a?(Exception)
          item[:msg] = msg.to_s
          set_exc(item, msg)
        elsif msg.is_a?(Hash)
          item[:msg] = @default_message unless msg.key?(:msg)
          item.merge!(msg)
        else
          item[:msg] = msg.to_s
        end
      elsif data.nil?  # 2 args
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
      elsif msg        # 3 args
        set_exc(item, ex) if ex.is_a?(Exception)
        item.merge!(data) if data.is_a?(Hash)
        item[:msg] = msg.to_s
      else             # No args
        item[:msg] = @default_message
      end
      item
    end

    def set_exc(item, exc)
      item[@exc_key] = @formatter.serialize_exc(exc)
    end
  end
end
