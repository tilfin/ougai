module Ougai
  module Logging
    attr_accessor :with_fields
    attr_writer :before_log

    def debug(message = nil, ex = nil, data = nil, &block)
      return true if level > Logger::DEBUG
      args = block ? yield : [message, ex, data]
      append(Logger::DEBUG, args)
    end

    def info(message = nil, ex = nil, data = nil, &block)
      return true if level > Logger::INFO
      args = block ? yield : [message, ex, data]
      append(Logger::INFO, args)
    end

    def warn(message = nil, ex = nil, data = nil, &block)
      return true if level > Logger::WARN
      args = block ? yield : [message, ex, data]
      append(Logger::WARN, args)
    end

    def error(message = nil, ex = nil, data = nil, &block)
      return true if level > Logger::ERROR
      args = block ? yield : [message, ex, data]
      append(Logger::ERROR, args)
    end

    def fatal(message = nil, ex = nil, data = nil, &block)
      return true if level > Logger::FATAL
      args = block ? yield : [message, ex, data]
      append(Logger::FATAL, args)
    end

    def unknown(message = nil, ex = nil, data = nil, &block)
      args = block ? yield : [message, ex, data]
      append(Logger::UNKNOWN, args)
    end

    def child(fields = {})
      ChildLogger.new(self, fields)
    end

    def chain(_severity, _args, _fields, _hooks)
      raise NotImplementedError
    end

    protected

    def append(severity, args)
      raise NotImplementedError
    end

    def merge_fields(base_data, new_data)
      base_data.merge(new_data) do |_, base_val, new_val|
        if base_val.is_a?(Array) and new_val.is_a?(Array)
          (base_val + new_val).uniq
        else
          new_val
        end
      end
    end
  end
end
