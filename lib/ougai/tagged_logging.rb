# frozen_string_literal: true

module Ougai
  # Alternative ActiveSupport::TaggedLogging for Ougai::Logger
  # @see https://api.rubyonrails.org/classes/ActiveSupport/TaggedLogging.html
  # @example Use this
  #    logger = Ougai::Logger.new(STDOUT)
  #    logger.formatter = Ougai::Formatters::Pino.new
  #    logger = Ougai::TaggedLogging.new(logger, 'TAG')
  #    logger.tagged('BCX') { logger.info 'Stuff' }                             # { ... ,"msg":"Stuff","TAG":["BCX"]}
  #    logger.tagged('BCX', "Jason") { logger.info 'Stuff' }                    # { ... ,"msg":"Stuff","TAG":["BCX","Jason"]}
  #    logger.tagged('BCX') { logger.tagged('Jason') { logger.info 'Stuff' } }  # { ... ,"msg":"Stuff","TAG":["BCX","Jason"]}
  module TaggedLogging
    # @attr [Ougai::Logger] logger Target logger
    # @attr [Symbol|String] tags_key The field name of tags.
    # @see https://api.rubyonrails.org/classes/ActiveSupport/TaggedLogging.html#method-c-new
    def self.new(logger, tags_key = :tags)
      tag_logger = logger.child
      tag_logger.before_log = lambda do |data|
        tags = tag_logger.current_tags
        data[tags_key] = tags unless tags.empty?
      end
      tag_logger.extend(self)
    end

    # @see https://api.rubyonrails.org/classes/ActiveSupport/TaggedLogging.html#method-i-tagged
    def tagged(*tags)
      new_tags = push_tags(*tags)
      yield self
    ensure
      pop_tags(new_tags.size)
    end

    # @deprecated
    # @see https://api.rubyonrails.org/classes/ActiveSupport/TaggedLogging.html#method-i-flush
    def flush
      clear_tags!
    end

    def push_tags(*tags)
      tags.flatten.reject { |t| t.nil? || t.empty? }.tap do |new_tags|
        current_tags.concat new_tags
      end
    end

    def pop_tags(size = 1)
      current_tags.pop size
    end

    def clear_tags!
      current_tags.clear
    end

    def current_tags
      # We use our object ID here to avoid conflicting with other instances
      thread_key = @thread_key ||= "ougai_tagged_logging_tags:#{object_id}"
      Thread.current[thread_key] ||= []
    end
  end
end
