require 'spec_helper'

describe Ougai::Formatters::Pino do
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
      stack: "error1.rb\n    error2.rb"
    }
  end

  let(:formatter) { described_class.new }

  context '#initialize' do
    let(:appname) { 'dummy app name' }

    it 'suceeds with arguments' do
      fmt = described_class.new(appname)
      expect(fmt.app_name).to eq(appname)
    end
  end

  context 'jsonize is true and with_newline is true' do
    let!(:time_epoc_msec) { 1518710101026 }

    subject { formatter.call('DEBUG', Time.now, nil, data) }

    before { Timecop.freeze(Time.at(time_epoc_msec / 1000.0)) }
    after { Timecop.return }

    it 'includes valid strings' do
      expect(subject).to end_with("\n")
      result = JSON.parse(subject.chomp, symbolize_names: true)
      expect(result).to include(data.merge(level: 20))
      expect(result[:time]).to eq(time_epoc_msec)
    end
  end

  context 'jsonize is false' do
    before do
      formatter.jsonize = false
    end

    context 'when severity is TRACE' do
      subject { formatter.call('TRACE', Time.now, nil, data) }

      it 'includes valid hash' do
        expect(subject).to include(data.merge(level: 10))
        expect(subject[:time]).to be_an_instance_of(Time)
      end
    end

    context 'when severity is DEBUG' do
      subject { formatter.call('DEBUG', Time.now, nil, data) }

      it 'includes valid hash' do
        expect(subject).to include(data.merge(level: 20))
        expect(subject[:time]).to be_an_instance_of(Time)
      end
    end

    context 'when severity is INFO' do
      subject { formatter.call('INFO', Time.now, nil, data) }

      it 'includes valid hash' do
        expect(subject).to include(data.merge(level: 30))
        expect(subject[:time]).to be_an_instance_of(Time)
      end
    end

    context 'when severity is WARN' do
      subject { formatter.call('WARN', Time.now, nil, data) }

      it 'includes valid hash' do
        expect(subject).to include(data.merge(level: 40))
        expect(subject[:time]).to be_an_instance_of(Time)
      end
    end

    context 'when severity is ERROR' do
      subject {
        data.delete(:msg)
        formatter.call('ERROR', Time.now, nil, data.merge({ err: err }))
      }

      it 'includes valid hash' do
        expect(subject).to include({
          level: 50, type: 'Error',
          msg: 'it is dummy.',
          stack: "DummyError: it is dummy.\n    error1.rb\n    error2.rb"
        })
        expect(subject[:time]).to be_an_instance_of(Time)
      end
    end

    context 'when severity is FATAL' do
      subject { formatter.call('FATAL', Time.now, nil, { msg: 'TheEnd', err: err }) }

      it 'includes valid hash' do
        expect(subject).to include({
          level: 60, type: 'Error',
          msg: 'TheEnd',
          stack: "DummyError: it is dummy.\n    error1.rb\n    error2.rb"
        })
        expect(subject[:time]).to be_an_instance_of(Time)
      end
    end

    context 'when severity is UNKNOWN' do
      subject { formatter.call('ANY', Time.now, nil, { msg: 'unknown msg' }) }

      it 'includes valid hash' do
        expect(subject).to include(level: 70, msg: 'unknown msg')
      end
    end
  end

  context 'with_newline is false' do
    before do
      formatter.with_newline = false
    end

    subject { formatter.call('INFO', Time.now, nil, data) }

    it 'includes valid strings' do
      expect(subject).not_to end_with("\n")
      result = JSON.parse(subject, symbolize_names: true)
      expect(result).to include(data.merge(level: 30))
      expect(result[:time]).to be > 1518710101026
    end
  end

  describe '#datetime_format' do
    it 'is not supported' do
      expect{ formatter.datetime_format = '%I:%M:%S %p' }.to raise_error(NotImplementedError)
    end
  end
end
