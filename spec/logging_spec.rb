require 'spec_helper'

describe Ougai::Logging do
  describe '#weak_merge!' do
    let(:target) { m = described_class; Class.new{ include m }.new }

    it 'merges with unique elements in array' do
      result = nil
      target.instance_eval do
        result = weak_merge!({ foo: [1, 2], bar: 'base', baz: ['A'] },
                             { foo: [2, 3], bar: 'inferior', baz: ['B'] })
      end
      expect(result[:foo]).to eq([2, 3, 1])
      expect(result[:bar]).to eq('base')
      expect(result[:baz]).to eq(['B', 'A'])
    end
  end
end
