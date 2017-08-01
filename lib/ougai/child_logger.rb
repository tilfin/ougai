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

    def chain(severity, args, fields)
      @parent.chain(severity, args, merge_fields(@with_fields, fields))
    end

    protected

    def append(severity, args)
      @parent.chain(severity, args, @with_fields)
    end
  end
end
