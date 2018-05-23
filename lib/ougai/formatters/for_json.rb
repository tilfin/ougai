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
      @serializer = Ougai::Serializer.for_json
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

    # requires convert_time(data) method
    def dump(data)
      return data unless @jsonize
      convert_time(data)
      str = @serializer.serialize(data)
      str << "\n" if @with_newline
      str
    end
  end
end
