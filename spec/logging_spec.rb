require 'spec_helper'

describe Ougai::Logging do
  subject do
    m = described_class

    Class.new do
      include m

      def level
        -1
      end
    end.new
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

  describe '#add' do
    context 'severity is specified level' do
      it 'calls append with specified level' do
        data = double('data')
        expect(subject).to receive(:append).with(::Logger::Severity::DEBUG, ['debug message', data, nil])
        subject.add(::Logger::Severity::DEBUG, 'debug message', data)
      end
    end

    context 'severity is nil' do
      it 'calls append with UNKNOWN level' do
        expect(subject).to receive(:append).with(::Logger::Severity::UNKNOWN, ['message', nil, nil])
        subject.add(nil, 'message')
      end
    end

    context 'block given' do
      it 'calls append with yielded arguments' do
        expect(subject).to receive(:append).with(::Logger::Severity::WARN, ['block message'])
        subject.log(::Logger::Severity::WARN) { ['block message'] }
      end
    end
  end

  describe '#log' do
    context 'severity is specified' do
      it 'calls append with specified level' do
        ex = Exception.new
        expect(subject).to receive(:append).with(::Logger::Severity::FATAL, ['fatal message', ex, nil])
        subject.log(::Logger::Severity::FATAL, 'fatal message', ex)
      end
    end

    context 'severity is nil' do
      it 'calls append with UNKNOWN level' do
        expect(subject).to receive(:append).with(::Logger::Severity::UNKNOWN, ['message', nil, nil])
        subject.log(nil, 'message')
      end
    end

    context 'block given' do
      it 'calls append with yielded arguments' do
        ex = Exception.new
        data = double('data')
        expect(subject).to receive(:append).with(::Logger::Severity::INFO, ['block message', ex, data])
        subject.log(::Logger::Severity::INFO) { ['block message', ex, data] }
      end
    end
  end
end
