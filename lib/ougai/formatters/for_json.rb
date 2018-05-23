# frozen_string_literal: true

require 'oj'

module Ougai
  # The features for JSON formatter
  # @attr [Boolean] jsonize Whether log should converts JSON
  # @attr [Boolean] with_newline Whether tailing NL should be appended
  module Formatters::ForJson
    attr_accessor :jsonize, :with_newline

    protected

    def init_opts_for_json(opts)
      @jsonize = opts.fetch(:jsonize, true)
      @with_newline = opts.fetch(:with_newline, true)
    end

    def to_level(severity)
      case severity
      when 'TRACE'
        10
      when 'DEBUG'
        20
      when 'INFO'
        30
      when 'WARN'
        40
      when 'ERROR'
        50
      when 'FATAL'
        60
      else
        70
      end
    end

    OJ_OPTIONS = { mode: :custom, time_format: :xmlschema,
                   use_as_json: true, use_to_hash: true, use_to_json: true }

    # requires convert_time(data) method
    def dump(data)
      return data unless @jsonize
      convert_time(data)
      str = Oj.dump(data, OJ_OPTIONS)
      str << "\n" if @with_newline
      str
    end
  end
end
