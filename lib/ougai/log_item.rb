# frozen_string_literal: true

module Ougai
  class LogItem
    attr_accessor :msg, :exc, :data

    def initialize(default_msg, args)
      @default_msg = default_msg
      @exc = nil
      @data = {}

      a1, a2, a3 = args
      if a1.nil?
        @msg = @default_msg
      elsif a2.nil?
        create_item_with_1arg(a1)
      elsif a3.nil?
        create_item_with_2args(a1, a2)
      else
        create_item_with_3args(a1, a2, a3)
      end
    end

    private

    def create_item_with_1arg(arg)
      if arg.is_a?(Exception)
        @msg = arg.to_s
        @exc = arg
      elsif arg.is_a?(String)
        @msg = arg
      else
        @data = as_hash(arg)
        @msg = @data.delete(:msg) || @default_msg
      end
    end

    def create_item_with_2args(arg1, arg2)
      if arg2.is_a?(Exception) # msg, exc
        @msg = arg1.to_s
        @exc = arg2
      elsif arg1.is_a?(Exception) # exc, data
        @exc = arg1
        @data = as_hash(arg2)
        @msg = @data.delete(:msg) || @default_msg
      else # msg, data
        @msg = arg1.to_s
        @data = as_hash(arg2)
      end
    end

    def create_item_with_3args(msg, exc, data)
      @exc = exc
      @data = as_hash(data)
      @msg = msg.to_s
    end

    def as_hash(data)
      if data.is_a?(Hash)
        data
      elsif data.respond_to?(:to_hash)
        data.to_hash
      else
        { data: data }
      end
    end
  end
end
