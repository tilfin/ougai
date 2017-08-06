module Ougai
  class ChildLogger
    include Logging

    def initialize(parent, fields)
      @parent = parent
      @with_fields = fields
    end

    def level
      @parent.level
    end

    def chain(severity, args, fields, hooks)
      hooks.push(@before_log) if @before_log
      @parent.chain(severity, args, merge_fields(@with_fields, fields), hooks)
    end

    protected

    def append(severity, args)
      hooks = @before_log ? [@before_log] : []
      @parent.chain(severity, args, @with_fields, hooks)
    end
  end
end
