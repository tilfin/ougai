module Ougai
  # Logging
  module Logging
    attr_accessor :with_fields
    attr_writer :before_log

    # Log any one or more of a message, an exception and structured data as DEBUG.
    # @param message [String] The message to log. Use default_message if not specified.
    # @param ex [Exception] The exception or the error
    # @param data [Object] Any structured data
    def debug(message = nil, ex = nil, data = nil, &block)
      log(Logger::DEBUG, message, ex, data, block)
    end

    # Log any one or more of a message, an exception and structured data as INFO.
    # @param message [String] The message to log. Use default_message if not specified.
    # @param ex [Exception] The exception or the error
    # @param data [Object] Any structured data
    def info(message = nil, ex = nil, data = nil, &block)
      log(Logger::INFO, message, ex, data, block)
    end

    # Log any one or more of a message, an exception and structured data as WARN.
    # @param message [String] The message to log. Use default_message if not specified.
    # @param ex [Exception] The exception or the error
    # @param data [Object] Any structured data
    def warn(message = nil, ex = nil, data = nil, &block)
      log(Logger::WARN, message, ex, data, block)
    end

    # Log any one or more of a message, an exception and structured data as ERROR.
    # @param message [String] The message to log. Use default_message if not specified.
    # @param ex [Exception] The exception or the error
    # @param data [Object] Any structured data
    def error(message = nil, ex = nil, data = nil, &block)
      log(Logger::ERROR, message, ex, data, block)
    end

    # Log any one or more of a message, an exception and structured data as FATAL.
    # @param message [String] The message to log. Use default_message if not specified.
    # @param ex [Exception] The exception or the error
    # @param data [Object] Any structured data
    def fatal(message = nil, ex = nil, data = nil, &block)
      log(Logger::FATAL, message, ex, data, block)
    end

    # Log any one or more of a message, an exception and structured data as UNKNOWN.
    # @param message [String] The message to log. Use default_message if not specified.
    # @param ex [Exception] The exception or the error
    # @param data [Object] Any structured data
    def unknown(message = nil, ex = nil, data = nil, &block)
      args = block ? yield : [message, ex, data]
      append(Logger::UNKNOWN, args)
    end

    # Creates a child logger and returns it.
    # @param fields [Hash] The fields appending to all logs
    # @return [ChildLogger] A created child logger
    def child(fields = {})
      ChildLogger.new(self, fields)
    end

    # @private
    def chain(_severity, _args, _fields, _hooks)
      raise NotImplementedError
    end

    protected

    # @private
    def append(severity, args)
      raise NotImplementedError
    end

    # @private
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
