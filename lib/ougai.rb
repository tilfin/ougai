require 'ougai/version'
require 'ougai/bunyan_formatter'
require 'logger'
require 'time'

module Ougai
  class Logger < ::Logger
    attr_accessor :default_message, :app_name
    attr_accessor :ex_key, :ex_trace_indent

    def initialize(*args)
      super(*args)
      @default_message = 'No message'
      @ex_key = :err
      @ex_trace_indent = 2
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
      BunyanFormatter.new
    end

    private

    def to_item(msg, ex, data)
      item = {}
      if ex.nil?       # 1 arg
        if msg.is_a?(Exception)
          item[:msg] = msg.to_s
          item[@ex_key] = serialize_ex(msg)
        elsif msg.is_a?(Hash)
          item[:msg] = @default_message unless msg.key?(:msg)
          item.merge!(msg)
        else
          item[:msg] = msg.to_s
        end
      elsif data.nil?  # 2 args
        if ex.is_a?(Exception)
          item[:msg] = msg.to_s
          item[@ex_key] = serialize_ex(ex)
        elsif ex.is_a?(Hash)
          item.merge!(ex)
          if msg.is_a?(Exception)
            item[@ex_key] = serialize_ex(msg)
          else
            item[:msg] = msg.to_s
          end
        end
      elsif msg        # 3 args
        item[@ex_key] = serialize_ex(ex) if ex.is_a?(Exception)
        item.merge!(data) if data.is_a?(Hash)
        item[:msg] = msg.to_s
      else             # No args
        item[:msg] = @default_message
      end
      item
    end

    def serialize_ex(ex)
      err = {
        name: ex.class.name,
        message: ex.to_s
      }
      if ex.backtrace
        sp = "\n" + ' ' * @ex_trace_indent
        err[:stack] = ex.backtrace.join(sp)
      end
      err
    end
  end
end
