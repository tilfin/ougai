# frozen_string_literal: true

module Ougai
  # A logger created by the `child` method of parent logger
  class ChildLogger
    include Logging

    # @private
    def initialize(parent, fields)
      @before_log = nil
      @parent = parent
      @with_fields = fields
    end

    def level
      @parent.level
    end

    # Whether the current severity level allows for logging DEBUG.
    # @return [Boolean] true if allows
    def debug?
      @parent.debug?
    end

    # Whether the current severity level allows for logging INFO.
    # @return [Boolean] true if allows
    def info?
      @parent.info?
    end

    # Whether the current severity level allows for logging WARN.
    # @return [Boolean] true if allows
    def warn?
      @parent.warn?
    end

    # Whether the current severity level allows for logging ERROR.
    # @return [Boolean] true if allows
    def error?
      @parent.error?
    end

    # Whether the current severity level allows for logging FATAL.
    # @return [Boolean] true if allows
    def fatal?
      @parent.fatal?
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
