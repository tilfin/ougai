require 'spec_helper'
require 'ougai/colors/configuration'
require 'ougai/logging'

describe Ougai::Colors::Configuration do
  let(:default_cfg) { Ougai::Colors::Configuration.default_configuration }
  let(:trace)       { 'TRACE' }
  let(:debug)       { 'DEBUG' }
  let(:info)        { 'INFO' }
  let(:warn)        { 'WARN' }
  let(:error)       { 'ERROR' }
  let(:fatal)       { 'FATAL' }
  let(:any)         { 'ANY' }
  let(:severities)  { [trace, debug, info, warn, error, fatal, any] }
  let(:severities_sym) { [:trace, :debug, :info, :warn, :error, :fatal, :any] }

  describe 'default configuration' do
    it 'handles all severities' do
      expect(default_cfg[:severity]).to be_a(Hash)
      severities_sym.each do |level|
        # Ensure value is present. Value is not checked
        expect(default_cfg[:severity][level]).to be_a(String)
      end
    end
  end

  context 'with no configuration input' do
    subject { Ougai::Colors::Configuration.new }

    describe '#initialize' do
      it 'has default configuration' do
        expect(subject.instance_variable_get(:@config)).to eq(default_cfg)
      end
    end
  end

  context 'with a complete configuration' do
    let(:input_cfg) do
      {
        severity: {
          trace: 'some_value', debug: 'some_value', info: 'some_value',
          warn: 'some_value', error: 'some_value', fatal: 'some_value',
          any: 'some_value'
        },
        datetime: 'some color',
        msg: {
          trace: 'trace_value', debug: 'debug_value', info: 'info_value',
          warn: 'warn_value', error: 'error_value', fatal: 'fatal_value',
          any: 'any_value'
        }
      }
    end
    subject { Ougai::Colors::Configuration.new(input_cfg) }

    describe '#initialize' do
      it 'has input as configuration' do
        expect(subject.instance_variable_get(:@config)).to eq(input_cfg)
      end
    end

    describe '#get_color_for' do
      context 'with a String value' do
        it 'returns the single value regardless severity' do
          severities.each do |lvl|
            expect(subject.get_color_for(:datetime, lvl)).to eq('some color')
          end
        end
      end
      context 'with a Hash value' do
        it 'returns the single value depending on severity' do
          severities.each do |lvl|
            expect(subject.get_color_for(:msg, lvl)).to eq(lvl.downcase + '_value')
          end
        end
      end
    end
  end

  context 'with a configuration with inheritance' do
    let(:input_cfg) do
      # datetime should refer to :severity for optimum but for the sake of testing
      { msg: :severity, datetime: :msg}
    end
    subject { Ougai::Colors::Configuration.new(input_cfg) }

    describe '#get_color_for' do
      it 'takes inherited color (direct inheritance)' do
        severities.each do |lvl|
          expect(subject.get_color_for(:msg, lvl)).to eq(subject.get_color_for(:severity, lvl))
        end
      end
      it 'takes inherited color (two-levels inheritance)' do
        severities.each do |lvl|
          expect(subject.get_color_for(:datetime, lvl)).to eq(subject.get_color_for(:severity, lvl))
        end
      end
    end

  end

  context 'with an severity color' do
    let(:uniq_value) { 'an unique color' }
    subject { Ougai::Colors::Configuration.new(severity: uniq_value) }
    let(:cfg) { subject.instance_variable_get(:@config) }

    describe '.initialize' do
      it 'has severity configuration reduced to a single value' do
        expect(cfg[:severity]).to be_a(String)
        expect(cfg[:severity]).to eq(uniq_value)
      end
    end

    describe '#get_color_for' do
      it 'returns the same severity value regardless severity' do
        severities.each do |lvl|
          expect(subject.get_color_for(:severity, lvl)).to eq(uniq_value)
        end
      end
    end
  end

  context 'without severity configuration' do
    let(:input_cfg) do
      { datetime: :severity, msg: 'some irrelevant value' }
    end
    subject { Ougai::Colors::Configuration.new(input_cfg) }
    let(:cfg) { subject.instance_variable_get(:@config) }

    describe '#initialize' do
      it 'has default severity values' do
        expect(cfg[:severity]).to eq(default_cfg[:severity])
      end

      it 'has input values' do
        expect(cfg[:datetime]).to eq(input_cfg[:datetime])
        expect(cfg[:msg]).to eq(input_cfg[:msg])
      end
    end
  end

  context 'with partial severity configuration' do
    let(:input_cfg) { { severity: { info: 'some_value', warn: 'some_value' }} }
    subject         { Ougai::Colors::Configuration.new(input_cfg) }
    let(:cfg)       { subject.instance_variable_get(:@config) }

    describe '#initialize' do
      it 'takes values undefined in default from input' do
        expect(cfg[:datetime]).to eq(input_cfg[:datetime])
      end

      it 'has input values having precedence over default values' do
        expect(cfg[:severity][:info]).to eq(input_cfg[:severity][:info])
        expect(cfg[:severity][:warn]).to eq(input_cfg[:severity][:warn])
      end

      it 'takes values undefined in input from default' do
        expect(cfg[:severity][:trace]).to eq(default_cfg[:severity][:trace])
        expect(cfg[:severity][:debug]).to eq(default_cfg[:severity][:debug])
        expect(cfg[:severity][:error]).to eq(default_cfg[:severity][:error])
        expect(cfg[:severity][:fatal]).to eq(default_cfg[:severity][:fatal])
      end
    end
  end

end
