# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'json'

describe Ougai::TaggedLogging do
  let(:output) { StringIO.new }
  let(:logger) { Ougai::TaggedLogging.new(Ougai::Logger.new(output)) }

  subject { output.string.split("\n").map { |line| JSON.parse(line, symbolize_names: true) } }

  it 'tagged once' do
    logger.tagged('BCX') do
      logger.info 'Funky time'
    end

    expect(subject[0][:tags]).to eq(['BCX'])
    expect(subject[0][:msg]).to eq('Funky time')
  end

  it 'tagged twice' do
    logger.tagged('BCX') { logger.tagged('Jason') { logger.info 'Funky time' } }

    expect(subject[0][:tags]).to eq(%w[BCX Jason])
    expect(subject[0][:msg]).to eq('Funky time')
  end

  it 'tagged thrice at once' do
    logger.tagged('BCX', 'Jason', 'New') { logger.info 'Funky time' }

    expect(subject[0][:tags]).to eq(%w[BCX Jason New])
    expect(subject[0][:msg]).to eq('Funky time')
  end

  it 'tagged are flattened' do
    logger.tagged('BCX', %w[Jason New]) { logger.info 'Funky time' }

    expect(subject[0][:tags]).to eq(%w[BCX Jason New])
    expect(subject[0][:msg]).to eq('Funky time')
  end

  it 'provides access to the logger instance' do
    logger.tagged('BCX') { |logger| logger.info 'Funky time' }

    expect(subject[0][:tags]).to eq(['BCX'])
    expect(subject[0][:msg]).to eq('Funky time')
  end

  it 'tagged once with blank and nil' do
    logger.tagged(nil, '', 'New') { logger.info 'Funky time' }

    expect(subject[0][:tags]).to eq(['New'])
    expect(subject[0][:msg]).to eq('Funky time')
  end

  it 'keeps each tag in their own thread' do
    logger.tagged('BCX') do
      Thread.new do
        logger.info 'Dull story'
        logger.tagged('OMG') { logger.info 'Cool story' }
      end.join
      logger.info 'Funky time'
    end

    expect(subject[0][:msg]).to eq('Dull story')
    expect(subject[1][:tags]).to eq(['OMG'])
    expect(subject[1][:msg]).to eq('Cool story')
    expect(subject[2][:tags]).to eq(['BCX'])
    expect(subject[2][:msg]).to eq('Funky time')
  end

  it 'keeps each tag in their own instance' do
    other_output = StringIO.new
    other_logger = Ougai::TaggedLogging.new(Ougai::Logger.new(other_output))

    logger.tagged('OMG') do
      other_logger.tagged('BCX') do
        logger.info 'Cool story'
        other_logger.info 'Funky time'
      end
    end

    expect(subject[0][:tags]).to eq(['OMG'])
    expect(subject[0][:msg]).to eq('Cool story')

    other_log = JSON.parse(other_output.string, symbolize_names: true)
    expect(other_log[:tags]).to eq(['BCX'])
    expect(other_log[:msg]).to eq('Funky time')
  end

  it 'cleans up the taggings on flush' do
    logger.tagged('BCX') do
      Thread.new do
        logger.tagged('OMG') do
          logger.flush
          logger.info 'Cool story'
        end
      end.join
    end

    expect(subject[0][:tags]).to be_nil
    expect(subject[0][:msg]).to eq('Cool story')
  end

  it 'mixed levels of tagging' do
    logger.tagged('BCX') do
      logger.tagged('Jason') { logger.info 'Funky time' }
      logger.info 'Junky time!'
    end

    expect(subject[0][:tags]).to eq(%w[BCX Jason])
    expect(subject[0][:msg]).to eq('Funky time')
    expect(subject[1][:tags]).to eq(['BCX'])
    expect(subject[1][:msg]).to eq('Junky time!')
  end
end
