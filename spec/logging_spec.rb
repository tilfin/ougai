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

  describe '#child' do
    let!(:fields) { double('fields') }
    let!(:child_logger) { double('child logger') }

    context 'block is not given' do
      it 'returns child logger' do
        expect(Ougai::ChildLogger).to receive(:new).with(subject, fields).and_return(child_logger)
        expect(subject.child(fields)).to eq(child_logger)
      end
    end

    context 'block is given' do
      it 'passes child logger' do
        expect(Ougai::ChildLogger).to receive(:new).with(subject, fields).and_return(child_logger)
        subject.child(fields) do |cl|
          expect(cl).to eq(child_logger)
        end
      end
    end
  end
end
