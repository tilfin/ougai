require 'ougai/version'
require 'ougai/formatters/base'
require 'ougai/formatters/bunyan_formatter'
require 'ougai/formatters/readable_formatter'
require 'logger'
require 'time'

module Ougai
  class Logger < ::Logger
    attr_accessor :default_message, :app_name
    attr_accessor :exc_key

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
      Formatters::BunyanFormatter.new
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
          item[@ex_key] = serialize_exc(ex)
        elsif ex.is_a?(Hash)
          item.merge!(ex)
          if msg.is_a?(Exception)
            item[@ex_key] = serialize_exc(msg)
          else
            item[:msg] = msg.to_s
          end
        end
      elsif msg        # 3 args
        item[@ex_key] = serialize_exc(ex) if ex.is_a?(Exception)
        item.merge!(data) if data.is_a?(Hash)
        item[:msg] = msg.to_s
      else             # No args
        item[:msg] = @default_message
      end
      item
    end

    def serialize_ex(ex)
      @formatter.serialize_exc(ex)
    end
  end
end
