require 'spec_helper'

describe Ougai::Logging do
  subject do
    m = described_class
    Class.new { include m }.new
  end

  describe '#weak_merge!' do
    it 'merges with unique elements in array' do
      result = nil
      subject.instance_eval do
        result = weak_merge!({ foo: [1, 2], bar: 'base', baz: ['A'] },
                             { foo: [2, 3], bar: 'inferior', baz: ['B'] })
      end
      expect(result[:foo]).to eq([2, 3, 1])
      expect(result[:bar]).to eq('base')
      expect(result[:baz]).to eq(['B', 'A'])
    end
  end

  describe '#chain' do
    it 'is not implemented' do
      expect{ subject.chain(:arg1, :arg2, :arg3, :arg4) }.to raise_error(NotImplementedError)
    end
  end

  describe '#append' do
    it 'is not implemented' do
      expect{ subject.send(:append, :arg1, :arg2) }.to raise_error(NotImplementedError)
    end
  end
end
