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

  describe '#initialize' do
    let(:appname) { 'dummy app name' }

    it 'suceeds with arguments' do
      fmt = described_class.new(appname)
      expect(fmt.app_name).to eq(appname)
    end
  end

  describe '#call' do
    let!(:time_epoc_msec) { 1518710101026 }

    before { Timecop.freeze(Time.at(time_epoc_msec / 1000.0)) }
    after { Timecop.return }

    subject { formatter.call(log_level, Time.now, nil, data) }

    context 'jsonize is true and with_newline is true' do
      let!(:log_level) { 'DEBUG' }

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
        let!(:log_level) { 'TRACE' }

        it 'includes valid hash' do
          expect(subject).to include(data.merge(level: 10))
          expect(subject[:time]).to be_an_instance_of(Time)
        end
      end

      context 'when severity is DEBUG' do
        let!(:log_level) { 'DEBUG' }

        it 'includes valid hash' do
          expect(subject).to include(data.merge(level: 20))
          expect(subject[:time]).to be_an_instance_of(Time)
        end
      end

      context 'when severity is INFO' do
        let!(:log_level) { 'INFO' }

        it 'includes valid hash' do
          expect(subject).to include(data.merge(level: 30))
          expect(subject[:time]).to be_an_instance_of(Time)
        end
      end

      context 'when severity is WARN' do
        let!(:log_level) { 'WARN' }

        it 'includes valid hash' do
          expect(subject).to include(data.merge(level: 40))
          expect(subject[:time]).to be_an_instance_of(Time)
        end
      end

      context 'when severity is ERROR' do
        let!(:log_level) { 'ERROR' }

        before do
          data.delete(:msg)
          data.merge!({ err: err })
        end

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
        let!(:log_level) { 'FATAL' }

        let!(:data) do
          { msg: 'TheEnd', err: err }
        end

        it 'includes valid hash' do
          expect(subject).to include({
            level: 60, type: 'Error',
            msg: 'TheEnd',
            stack: "DummyError: it is dummy.\n    error1.rb\n    error2.rb"
          })
          expect(subject[:time]).to be_an_instance_of(Time)
        end

        context 'when severity is UNKNOWN' do
          let!(:log_level) { 'ANY' }

          let!(:data) do
            { msg: 'unknown msg' }
          end

          it 'includes valid hash' do
            expect(subject).to include(level: 70, msg: 'unknown msg')
          end
        end

        context 'with_newline is false' do
          before do
            formatter.with_newline = false
            formatter.jsonize = true
          end

          let!(:log_level) { 'INFO' }

          it 'includes valid strings' do
            expect(subject).not_to end_with("\n")
            result = JSON.parse(subject, symbolize_names: true)
            expect(result).to include(data.merge(level: 30))
            expect(result[:time]).to eq(time_epoc_msec)
          end
        end
      end
    end
  end

  describe '#datetime_format' do
    it 'is not supported' do
      expect{ formatter.datetime_format = '%I:%M:%S %p' }.to raise_error(NotImplementedError)
    end
  end
end
