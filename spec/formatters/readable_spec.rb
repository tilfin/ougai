require 'spec_helper'

describe Ougai::Formatters::Readable do
  let!(:re_start_with_datetime) { /^\[\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}(Z|[\+\-\:0-9]{4,6})]/ }
  let!(:trace_color)    { "\e[34m" }
  let!(:debug_color)    { "\e[37m" }
  let!(:info_color)     { "\e[36m" }
  let!(:warn_color)     { "\e[33m" }
  let!(:error_color)    { "\e[31m" }
  let!(:fatal_color)    { "\e[35m" }
  let!(:unknown_color)  { "\e[32m" }

  let(:data) do
    {
      msg: 'Log Message!',
      status: 200,
      method: 'GET',
      path: '/'
    }
  end

  let(:err) do
    {
      name: 'DummyError',
      message: 'it is dummy.',
      stack: "error1.rb\n  error2.rb"
    }
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

  describe '#initialize' do
    context 'when no custom sub-formatter' do 
      it 'has the default message formatter' do
        expect(subject.instance_variable_get(:@msg_formatter)).to be_a(Ougai::Formatters::Readable::MessageFormatter)
      end
      it 'has the default data formatter' do
        expect(subject.instance_variable_get(:@data_formatter)).to be_a(Ougai::Formatters::Readable::DataFormatter)
      end
      it 'has the default error formatter' do
        expect(subject.instance_variable_get(:@err_formatter)).to be_a(Ougai::Formatters::Readable::ErrorFormatter)
      end
    end
  end

  context 'when severity is TRACE' do
    subject { formatter.call('TRACE', Time.now, nil, data) }

    it 'includes valid strings' do
      expect(subject).to match(re_start_with_datetime)
      expect(subject).to include("#{trace_color}TRACE\e[0m: Log Message!")
      expect(subject.gsub(/\e\[([;\d]+)?m/, '')).to include(':status => 200')
    end
  end

  context 'when severity is DEBUG' do
    subject { formatter.call('DEBUG', Time.now, nil, data) }

    it 'includes valid strings' do
      expect(subject).to match(re_start_with_datetime)
      expect(subject).to include("#{debug_color}DEBUG\e[0m: Log Message!")
      expect(subject.gsub(/\e\[([;\d]+)?m/, '')).to include(':status => 200')
    end
  end

  context 'when severity is INFO' do
    subject { formatter.call('INFO', Time.now, nil, data) }

    it 'includes valid strings' do
      expect(subject).to match(re_start_with_datetime)
      expect(subject).to include("#{info_color}INFO\e[0m: Log Message!")
      expect(subject.gsub(/\e\[([;\d]+)?m/, '')).to include(':method => "GET"')
    end
  end

  context 'when severity is WARN' do
    subject { formatter.call('WARN', Time.now, nil, data) }

    it 'includes valid strings' do
      expect(subject).to match(re_start_with_datetime)
      expect(subject).to include("#{warn_color}WARN\e[0m: Log Message!")
      expect(subject.gsub(/\e\[([;\d]+)?m/, '')).to include(':path => "/"')
    end
  end

  context 'when severity is ERROR' do
    subject { formatter.call('ERROR', Time.now, nil, data.merge({ err: err })) }

    it 'includes valid strings' do
      expect(subject).to match(re_start_with_datetime)
      expect(subject).to include("#{error_color}ERROR\e[0m: Log Message!")
      expect(subject.gsub(/\e\[([;\d]+)?m/, '')).to include('DummyError (it is dummy.):')
    end
  end

  context 'when severity is FATAL' do
    subject { formatter.call('FATAL', Time.now, nil, { msg: 'TheEnd', err: err }) }

    it 'includes valid strings' do
      expect(subject).to match(re_start_with_datetime)
      expect(subject).to include("#{fatal_color}FATAL\e[0m: TheEnd")
      expect(subject.gsub(/\e\[([;\d]+)?m/, '')).to include("error1.rb\n  error2.rb")
    end
  end

  context 'when severity is UNKNOWN' do
    subject { formatter.call('ANY', Time.now, nil, { msg: 'unknown msg' }) }

    it 'includes valid strings' do
      expect(subject).to match(re_start_with_datetime)
      expect(subject).to include("#{unknown_color}ANY\e[0m: unknown msg")
    end
  end

  context 'when logger has excluded_fields' do
    subject do
      described_class.new(excluded_fields: [:status, :method]).call('DEBUG', Time.now, nil, data)
    end

    it 'includes valid strings' do
      expect(subject).to include("#{debug_color}DEBUG\e[0m: Log Message!")
      plain_subject = subject.gsub(/\e\[([;\d]+)?m/, '')
      expect(plain_subject).to include(':path => "/"')
      expect(plain_subject).not_to include(':status => 200')
      expect(plain_subject).not_to include(':method => "GET"')
    end
  end

  describe '#datetime_format' do
    subject do
      formatter.call('DEBUG', Time.now, nil, data)
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
