require "ougai/version"
require 'logger'
require 'socket'
require 'time'
require 'json'

module Ougai
  class Logger < Logger
    attr_accessor :default_message, :app_name

    def initialize(*args)
      super(*args)
      @default_message = 'No message'
      @app_name = File.basename($0, ".rb")
      @hostname = Socket.gethostname
      @formatter = create_formatter
    end

    def debug(message, ex = nil, data = {})
      super(to_item(message, ex, data))
    end

    def info(message, ex = nil, data = {})
      super(to_item(message, ex, data))
    end

    def warn(message, ex = nil, data = {})
      super(to_item(message, ex, data))
    end

    def error(message, ex = nil, data = {})
      super(to_item(message, ex, data))
    end

    def fatal(message, ex = nil, data = {})
      super(to_item(message, ex, data))
    end

    protected

    def create_formatter
      proc do |severity, time, progname, data|
        JSON.generate({
          name: progname || @app_name,
          hostname: @hostname,
          pid: $$,
          level: to_level(severity),
          time: time.iso8601(3),
          v: 0
        }.merge(data)) + "\n"
      end
    end

    private

    def to_item(msg, ex, data)
      item = {}
      if ex.nil? && msg.is_a?(Exception)
        item[:msg] = msg.to_s
        item[:err] = serialize_ex(msg)
      elsif ex
        item[:msg] = msg
        if ex.is_a?(Hash)
          item.merge!(ex)
        elsif ex.is_a?(Exception)
          item[:err] = serialize_ex(ex)
          item.merge!(data)
        end
      elsif msg.is_a?(Hash)
        item[:msg] = @default_message unless msg.key?(:msg)
        item.merge!(msg)
      else
        item[:msg] = msg
        item.merge!(data)
      end
      item
    end

    def serialize_ex(ex)
      err = {
        name: ex.class.name,
        message: ex.to_s
      }
      if ex.backtrace
        err[:stack] = ex.backtrace.join("\n  ")
      end
      err
    end

    def to_level(severity)
      case severity
      when 'INFO'
        30
      when 'WARN'
        40
      when 'ERROR'
        50
      when 'FATAL'
        60
      else # DEBUG
        20
      end
    end
  end
end