require 'spec_helper'

describe Ougai::Logging do
  describe '#merge_fields' do
    let(:target) { m = described_class; Class.new{ include m }.new }

    it 'merges with unique elements in array' do
      result = nil
      target.instance_eval do
        result = merge_fields({ foo: [1, 2], bar: 'base', baz: ['A'] },
                              { foo: [2, 3], bar: 'over', baz: ['B'] })
      end
      expect(result[:foo]).to eq([1, 2, 3])
      expect(result[:bar]).to eq('over')
      expect(result[:baz]).to eq(['A', 'B'])
    end
  end
end
