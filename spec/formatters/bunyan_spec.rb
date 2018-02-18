require 'spec_helper'

describe Ougai::Formatters::Bunyan do
  let(:data) do
    {
      msg: 'Log Message!',
      status: 200,
      method: 'GET',
      path: '/'
    }
  end

  let(:stack) { "error1.rb\n  error2.rb" }

  let(:err) do
    {
      name: 'DummyError',
      message: 'it is dummy.',
      stack: stack
    }
  end

  let(:formatter) { described_class.new }

  include_examples 'formatter#initialize',
    default_opts: {
      trace_indent: 2,
      trace_max_lines: 100,
      serialize_backtrace: true,
      jsonize: true,
      with_newline: true
    },
    options: {
      jsonize: false,
      with_newline: false
    }

  describe '#call' do
    subject { formatter.call(severity, Time.now, nil, data) }

    context 'jsonize is true and with_newline is true' do
      let!(:severity) { 'DEBUG' }

      it 'includes valid strings' do
        expect(subject).to end_with("\n")
        result = JSON.parse(subject.chomp, symbolize_names: true)
        expect(result).to include(data.merge(pid: $$, level: 20, v: 0))
        expect(result[:time]).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
      end
    end

    context 'jsonize is false' do
      before do
        formatter.jsonize = false
      end

      context 'when severity is TRACE' do
        let!(:severity) { 'TRACE' }

        it 'includes valid hash' do
          expect(subject).to include(data.merge(pid: $$, level: 10, v: 0))
          expect(subject[:time]).to be_an_instance_of(Time)
        end
      end

      context 'when severity is DEBUG' do
        let!(:severity) { 'DEBUG' }

        it 'includes valid hash' do
          expect(subject).to include(data.merge(pid: $$, level: 20, v: 0))
          expect(subject[:time]).to be_an_instance_of(Time)
        end
      end

      context 'when severity is INFO' do
        let!(:severity) { 'INFO' }

        it 'includes valid hash' do
          expect(subject).to include(data.merge(pid: $$, level: 30, v: 0))
          expect(subject[:time]).to be_an_instance_of(Time)
        end
      end

      context 'when severity is WARN' do
        let!(:severity) { 'WARN' }

        it 'includes valid hash' do
          expect(subject).to include(data.merge(pid: $$, level: 40, v: 0))
          expect(subject[:time]).to be_an_instance_of(Time)
        end
      end

      context 'when severity is ERROR' do
        let!(:severity) { 'ERROR' }

        before { data.merge!({ err: err }) }

        it 'includes valid hash' do
          expect(subject).to include(pid: $$, level: 50, v: 0, err: err)
          expect(subject[:time]).to be_an_instance_of(Time)
        end
      end

      context 'when severity is FATAL' do
        let!(:severity) { 'FATAL' }
        let!(:data) do
          { msg: 'TheEnd', err: err }
        end

        it 'includes valid hash' do
          expect(subject).to include(pid: $$, level: 60, v: 0, err: err)
          expect(subject[:time]).to be_an_instance_of(Time)
        end
      end

      context 'when severity is UNKNOWN' do
        let!(:severity) { 'ANY' }
        let!(:data) do
          { msg: 'unknown msg' }
        end

        it 'includes valid hash' do
          expect(subject).to include(pid: $$, level: 70, msg: 'unknown msg', v: 0)
        end
      end
    end

    context 'with_newline is false' do
      let!(:severity) { 'INFO' }

      before do
        formatter.with_newline = false
      end

      it 'includes valid strings' do
        expect(subject).not_to end_with("\n")
        result = JSON.parse(subject, symbolize_names: true)
        expect(result).to include(data.merge(pid: $$, level: 30, v: 0))
        expect(result[:time]).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
      end
    end
  end

  describe '#datetime_format' do
    context 'is time AM/PM format' do
      before do
        formatter.datetime_format = '%I:%M:%S %p'
      end

      it 'applys output' do
        subject = formatter.call('DEBUG', Time.now, nil, data)
        result = JSON.parse(subject, symbolize_names: true)
        expect(result[:time]).to match(/^\d{2}:\d{2}:\d{2} [AP]M$/)
      end
    end
  end
end
