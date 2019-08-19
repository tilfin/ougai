# frozen_string_literal: true

module Ougai
  # A logger created by the `child` method of parent logger
  class ChildLogger
    include Logging

    # @private
    def initialize(parent, fields)
      @before_log = nil
      @level = nil
      @parent = parent
      @with_fields = fields
    end

    # Creates a child logger and returns it.
    # @param fields [Hash] The fields appending to all logs
    # @return [ChildLogger] A created child logger
    def child(fields = {})
      ch = self.class.new(self, fields)

      if !block_given?
        ch
      else
        yield ch
      end
    end

    def level=(severity)
      if severity.is_a?(Integer)
        @level = severity
      elsif severity.is_a?(String)
        @level = from_label(severity.upcase)
      elsif severity.is_a?(Symbol)
        @level = from_label(severity.to_s.upcase)
      else
        @level = nil
      end
    end

    def level
      @level || @parent.level
    end

    alias sev_threshold= level=
    alias sev_threshold level

    # Whether the current severity level allows for logging DEBUG.
    # @return [Boolean] true if allows
    def debug?
      level <= DEBUG
    end

    # Whether the current severity level allows for logging INFO.
    # @return [Boolean] true if allows
    def info?
      level <= INFO
    end

    # Whether the current severity level allows for logging WARN.
    # @return [Boolean] true if allows
    def warn?
      level <= WARN
    end

    # Whether the current severity level allows for logging ERROR.
    # @return [Boolean] true if allows
    def error?
      level <= ERROR
    end

    # Whether the current severity level allows for logging FATAL.
    # @return [Boolean] true if allows
    def fatal?
      level <= FATAL
    end

    # @private
    def chain(severity, args, fields, hooks)
      hooks.push(@before_log) if @before_log
      @parent.chain(severity, args, weak_merge!(fields, @with_fields), hooks)
    end

    protected

    def append(severity, args)
      hooks = @before_log ? [@before_log] : []
      @parent.chain(severity, args, @with_fields.dup, hooks)
    end
  end
end
