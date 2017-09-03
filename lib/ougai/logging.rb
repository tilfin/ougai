module Ougai
  # Common Logging features
  module Logging
    attr_accessor :with_fields
    attr_writer :before_log

    module Severity
      include ::Logger::Severity
      TRACE = -1

      SEV_LABEL = %w(TRACE DEBUG INFO WARN ERROR FATAL ANY).each(&:freeze).freeze

      def to_label(severity)
        SEV_LABEL[severity + 1] || 'ANY'
      end
    end
    include Severity

    # Log any one or more of a message, an exception and structured data as TRACE.
    # @return [Boolean] true
    # @see Logging#debug
    def trace(message = nil, ex = nil, data = nil, &block)
      log(TRACE, message, ex, data, block)
    end

    # Log any one or more of a message, an exception and structured data as DEBUG.
    # If the block is given for delay evaluation, it returns them as an array or the one of them as a value.
    # @param message [String] The message to log. Use default_message if not specified.
    # @param ex [Exception] The exception or the error
    # @param data [Object] Any structured data
    # @yieldreturn [String|Exception|Object|Array] Any one or more of former parameters
    # @return [Boolean] true
    def debug(message = nil, ex = nil, data = nil, &block)
      log(DEBUG, message, ex, data, block)
    end

    # Log any one or more of a message, an exception and structured data as INFO.
    # @return [Boolean] true
    # @see Logging#debug
    def info(message = nil, ex = nil, data = nil, &block)
      log(INFO, message, ex, data, block)
    end

    # Log any one or more of a message, an exception and structured data as WARN.
    # @return [Boolean] true
    # @see Logging#debug
    def warn(message = nil, ex = nil, data = nil, &block)
      log(WARN, message, ex, data, block)
    end

    # Log any one or more of a message, an exception and structured data as ERROR.
    # @return [Boolean] true
    # @see Logging#debug
    def error(message = nil, ex = nil, data = nil, &block)
      log(ERROR, message, ex, data, block)
    end

    # Log any one or more of a message, an exception and structured data as FATAL.
    # @return [Boolean] true
    # @see Logging#debug
    def fatal(message = nil, ex = nil, data = nil, &block)
      log(FATAL, message, ex, data, block)
    end

    # Log any one or more of a message, an exception and structured data as UNKNOWN.
    # @return [Boolean] true
    # @see Logging#debug
    def unknown(message = nil, ex = nil, data = nil, &block)
      args = block ? yield : [message, ex, data]
      append(UNKNOWN, args)
    end

    # Whether the current severity level allows for logging TRACE.
    # @return [Boolean] true if allows
    def trace?
      level <= TRACE
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
