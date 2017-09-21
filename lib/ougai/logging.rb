module Ougai
  module Logging
    attr_accessor :with_fields
    attr_writer :before_log

    def debug(message = nil, ex = nil, data = nil, &block)
      log(Logger::DEBUG, message, ex, data, block)
    end

    def info(message = nil, ex = nil, data = nil, &block)
      log(Logger::INFO, message, ex, data, block)
    end

    def warn(message = nil, ex = nil, data = nil, &block)
      log(Logger::WARN, message, ex, data, block)
    end

    def error(message = nil, ex = nil, data = nil, &block)
      log(Logger::ERROR, message, ex, data, block)
    end

    def fatal(message = nil, ex = nil, data = nil, &block)
      log(Logger::FATAL, message, ex, data, block)
    end

    def unknown(message = nil, ex = nil, data = nil, &block)
      args = block ? yield : [message, ex, data]
      append(Logger::UNKNOWN, args)
    end

    def child(fields = {})
      ch = ChildLogger.new(self, fields)

      if !block_given?
        ch
      else
        yield ch
      end
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

    private

    def log(severity, message, ex, data, block)
      return true if level > severity
      args = block ? block.call : [message, ex, data]
      append(severity, args)
    end
  end
end
