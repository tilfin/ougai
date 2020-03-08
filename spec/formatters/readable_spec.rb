require 'spec_helper'

describe Ougai::Formatters::Readable do
  let!(:re_start_with_datetime) { /^\[\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}(Z|[\+\-\:0-9]{4,6})\]/ }

  let(:item) do
    Ougai::LogItem.new('default message', ['Log Message!', {
      status: 200,
      method: 'GET',
      path: '/'
    }])
  end

  class DummyError < Exception; end

  let(:ex) do
    ex = DummyError.new('it is dummy.')
    ex.set_backtrace(["error1.rb", "error2.rb"])
    ex
  end

  let(:formatter) { described_class.new }

  include_examples 'formatter#initialize',
    default_opts: {
      trace_indent: 4,
      trace_max_lines: 100,
      serialize_backtrace: true,
      plain: false,
      excluded_fields: []
    },
    options: {
      plain: true,
      excluded_fields: [:card_number]
    }

  context 'when severity is TRACE' do
    subject { formatter.call('TRACE', Time.now, nil, item) }

    it 'includes valid strings' do
      expect(subject).to match(re_start_with_datetime)
      expect(subject).to include("\e[0;34mTRACE\e[0m: Log Message!")
      expect(subject.gsub(/\e\[([;\d]+)?m/, '')).to include(':status => 200')
    end
  end

  context 'when severity is DEBUG' do
    subject { formatter.call('DEBUG', Time.now, nil, item) }

    it 'includes valid strings' do
      expect(subject).to match(re_start_with_datetime)
      expect(subject).to include("\e[0;37mDEBUG\e[0m: Log Message!")
      expect(subject.gsub(/\e\[([;\d]+)?m/, '')).to include(':status => 200')
    end
  end

  context 'when severity is INFO' do
    subject { formatter.call('INFO', Time.now, nil, item) }

    it 'includes valid strings' do
      expect(subject).to match(re_start_with_datetime)
      expect(subject).to include("\e[0;36mINFO\e[0m: Log Message!")
      expect(subject.gsub(/\e\[([;\d]+)?m/, '')).to include(':method => "GET"')
    end
  end

  context 'when severity is WARN' do
    subject { formatter.call('WARN', Time.now, nil, item) }

    it 'includes valid strings' do
      expect(subject).to match(re_start_with_datetime)
      expect(subject).to include("\e[0;33mWARN\e[0m: Log Message!")
      expect(subject.gsub(/\e\[([;\d]+)?m/, '')).to include(':path => "/"')
    end
  end

  context 'when severity is ERROR' do
    subject {
      item.exc = ex
      formatter.call('ERROR', Time.now, nil, item)
    }

    it 'includes valid strings' do
      expect(subject).to match(re_start_with_datetime)
      expect(subject).to include("\e[0;31mERROR\e[0m: Log Message!")
      expect(subject.gsub(/\e\[([;\d]+)?m/, '')).to include('DummyError (it is dummy.):')
    end
  end

  context 'when severity is FATAL' do
    subject {
      item.msg = 'TheEnd'
      item.exc = ex
      formatter.call('FATAL', Time.now, nil, item) }

    it 'includes valid strings' do
      expect(subject).to match(re_start_with_datetime)
      expect(subject).to include("\e[0;35mFATAL\e[0m: TheEnd")
      expect(subject.gsub(/\e\[([;\d]+)?m/, '')).to include("    error1.rb\n    error2.rb")
    end
  end

  context 'when severity is UNKNOWN' do
    subject {
      item.msg = 'unknown msg'
      formatter.call('ANY', Time.now, nil, item)
    }

    it 'includes valid strings' do
      expect(subject).to match(re_start_with_datetime)
      expect(subject).to include("\e[0;32mANY\e[0m: unknown msg")
    end
  end

  context 'when logger has excluded_fields' do
    subject do
      described_class.new(excluded_fields: [:status, :method]).call('DEBUG', Time.now, nil, item)
    end

    it 'includes valid strings' do
      expect(subject).to include("\e[0;37mDEBUG\e[0m: Log Message!")
      plain_subject = subject.gsub(/\e\[([;\d]+)?m/, '')
      expect(plain_subject).to include(':path => "/"')
      expect(plain_subject).not_to include(':status => 200')
      expect(plain_subject).not_to include(':method => "GET"')
    end
  end

  describe '#datetime_format' do
    subject do
      formatter.call('DEBUG', Time.now, nil, item)
    end

    context 'is time AM/PM format' do
      before do
        formatter.datetime_format = '%I:%M:%S %p'
      end

      it 'applys output' do
        expect(subject).to match(/^\[\d{2}:\d{2}:\d{2} [AP]M\]/)
      end
    end
  end

  describe '#serialize_backtrace' do
    it 'is not supported' do
      expect{ formatter.serialize_backtrace = false }.to raise_error(NotImplementedError)
    end
  end
end
