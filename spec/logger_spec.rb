require 'spec_helper'
require 'stringio'
require 'json'

describe Ougai::Logger do
  let(:pid) { Process.pid }

  matcher :be_log_message do |message, level|
    match do |actual|
      actual[:name] == 'rspec' \
       && actual[:msg] == message \
       && actual[:level] == level \
       && actual[:pid] == pid \
       && actual[:v] == 0
    end
  end

  matcher :include_data do |data|
    match do |actual|
      data.each do |key, expected|
        return false unless actual[key] == expected
      end
      true
    end
  end

  matcher :include_error do |expected|
    match do |actual|
      err = actual[:err]
      err[:message] == expected \
        && err[:name] = 'StandardError' \
        && err[:stack].include?('ougai/spec')
    end
  end

  let(:io) { StringIO.new }
  let(:logger) { described_class.new(io) }

  let(:item) do
    log_str = io.string
    begin
      JSON.parse(log_str, symbolize_names: true)
    rescue Exception => e
      nil
    end 
  end

  shared_examples 'log' do
    context 'with message' do
      it 'outputs valid' do
        logger.send(method, log_msg)
        expect(item).to be_log_message(log_msg, log_level)
      end

      it 'outputs valid by block' do
        logger.send(method) { log_msg }
        expect(item).to be_log_message(log_msg, log_level)
      end
    end

    context 'with exception' do
      it 'outputs valid' do
        begin
          raise StandardError, 'errmsg'
        rescue => ex
          logger.send(method, ex)
        end

        expect(item).to be_log_message('errmsg', log_level)
        expect(item).to include_error('errmsg')
      end

      it 'outputs valid by block' do
        begin
          raise StandardError, 'errmsg'
        rescue => ex
          logger.send(method) { ex }
        end

        expect(item).to be_log_message('errmsg', log_level)
        expect(item).to include_error('errmsg')
      end
    end

    context 'with data that contains msg' do
      it 'outputs valid' do
        logger.send(method, { msg: log_msg, data_id: 108, action: 'dump' })
        expect(item).to be_log_message(log_msg, log_level)
        expect(item).to include_data(data_id: 108, action: 'dump')
      end

      it 'outputs valid by block' do
        logger.send(method) do
          { msg: log_msg, data_id: 108, action: 'dump' }
        end
        expect(item).to be_log_message(log_msg, log_level)
        expect(item).to include_data(data_id: 108, action: 'dump')
      end
    end

    context 'with data that does not contain msg' do
      it 'outputs valid' do
        logger.send(method, { data_id: 109, action: 'dump' })
        expect(item).to be_log_message('No message', log_level)
        expect(item).to include_data(data_id: 109, action: 'dump')
      end

      it 'outputs valid by block' do
        logger.send(method) do
          { data_id: 109, action: 'dump' }
        end
        expect(item).to be_log_message('No message', log_level)
        expect(item).to include_data(data_id: 109, action: 'dump')
      end
    end

    context 'with message and data' do
      it 'outputs valid' do
        logger.send(method, log_msg, data_id: 99, action: 'insert')
        expect(item).to be_log_message(log_msg, log_level)
        expect(item).to include_data(data_id: 99, action: 'insert')
      end

      it 'outputs valid by block' do
        logger.send(method) { [log_msg, data_id: 99, action: 'insert'] }
        expect(item).to be_log_message(log_msg, log_level)
        expect(item).to include_data(data_id: 99, action: 'insert')
      end
    end

    context 'with message and exception' do
      it 'outputs valid' do
        begin
          raise StandardError, 'errmsg'
        rescue => ex
          logger.send(method, log_msg, ex)
        end

        expect(item).to be_log_message(log_msg, log_level)
        expect(item).to include_error('errmsg')
      end

      it 'outputs valid by block' do
        begin
          raise StandardError, 'errmsg'
        rescue => ex
          logger.send(method) { [log_msg, ex] }
        end

        expect(item).to be_log_message(log_msg, log_level)
        expect(item).to include_error('errmsg')
      end
    end

    context 'with exception and data' do
      it 'outputs valid' do
        begin
          raise StandardError, 'errmsg'
        rescue => ex
          logger.send(method, ex, something: { name: 'bar' })
        end

        expect(item).to include_error('errmsg')
        expect(item).to include_data(something: { name: 'bar' })
      end

      it 'outputs valid by block' do
        begin
          raise StandardError, 'errmsg'
        rescue => ex
          logger.send(method) do
            [ex, something: { name: 'bar' }]
          end
        end

        expect(item).to include_error('errmsg')
        expect(item).to include_data(something: { name: 'bar' })
      end
    end

    context 'with message, exception and data' do
      it 'outputs valid' do
        begin
          raise StandardError, 'errmsg'
        rescue => ex
          logger.send(method, log_msg, ex, something: { name: 'foo' })
        end

        expect(item).to be_log_message(log_msg, log_level)
        expect(item).to include_error('errmsg')
        expect(item).to include_data(something: { name: 'foo' })
      end

      it 'outputs valid by block' do
        begin
          raise StandardError, 'errmsg'
        rescue => ex
          logger.send(method) do
            [log_msg, ex, something: { name: 'foo' }]
          end
        end

        expect(item).to be_log_message(log_msg, log_level)
        expect(item).to include_error('errmsg')
        expect(item).to include_data(something: { name: 'foo' })
      end
    end
  end

  describe '#debug' do
    let(:log_level) { 20 }
    let(:log_msg) { 'debug message' }
    let(:method) { 'debug' }

    it_behaves_like 'log'
  end

  describe '#info' do
    let(:log_level) { 30 }
    let(:log_msg) { 'info message' }
    let(:method) { 'info' }

    it_behaves_like 'log'
  end

  describe '#warn' do
    let(:log_level) { 40 }
    let(:log_msg) { 'info message' }
    let(:method) { 'warn' }

    it_behaves_like 'log'
  end

  describe '#error' do
    let(:log_level) { 50 }
    let(:log_msg) { 'error message' }
    let(:method) { 'error' }

    it_behaves_like 'log'
  end

  describe '#fatal' do
    let(:log_level) { 60 }
    let(:log_msg) { 'fatal message' }
    let(:method) { 'fatal' }

    it_behaves_like 'log'
  end

  describe '#level' do
    context 'DEBUG' do
      let(:log_msg) { 'log message' }
      before { logger.level = Logger::DEBUG }

      it 'outputs debug message' do
        logger.debug(log_msg)
        expect(item).to be_log_message(log_msg, 20)
      end

      it 'outputs info message' do
        logger.info(log_msg)
        expect(item).to be_log_message(log_msg, 30)
      end

      it 'outputs warning message' do
        logger.warn(log_msg)
        expect(item).to be_log_message(log_msg, 40)
      end

      it 'outputs error message' do
        logger.error(log_msg)
        expect(item).to be_log_message(log_msg, 50)
      end

      it 'outputs fatal message' do
        logger.fatal(log_msg)
        expect(item).to be_log_message(log_msg, 60)
      end
    end

    context 'INFO' do
      let(:log_msg) { 'log message' }
      before { logger.level = Logger::INFO }

      it 'does not output debug message' do
        logger.debug(log_msg)
        expect(item).to be_nil
      end

      it 'outputs info message' do
        logger.info(log_msg)
        expect(item).to be_log_message(log_msg, 30)
      end

      it 'outputs warning message' do
        logger.warn(log_msg)
        expect(item).to be_log_message(log_msg, 40)
      end

      it 'outputs error message' do
        logger.error(log_msg)
        expect(item).to be_log_message(log_msg, 50)
      end

      it 'outputs fatal message' do
        logger.fatal(log_msg)
        expect(item).to be_log_message(log_msg, 60)
      end
    end

    context 'WARN' do
      let(:log_msg) { 'log message' }
      before { logger.level = Logger::WARN }

      it 'does not output debug message' do
        logger.debug(log_msg)
        expect(item).to be_nil
      end

      it 'does not output info message' do
        logger.info(log_msg)
        expect(item).to be_nil
      end

      it 'outputs warning message' do
        logger.warn(log_msg)
        expect(item).to be_log_message(log_msg, 40)
      end

      it 'outputs error message' do
        logger.error(log_msg)
        expect(item).to be_log_message(log_msg, 50)
      end

      it 'outputs fatal message' do
        logger.fatal(log_msg)
        expect(item).to be_log_message(log_msg, 60)
      end
    end

    context 'ERROR' do
      let(:log_msg) { 'log message' }
      before { logger.level = Logger::ERROR }

      it 'does not output debug message' do
        logger.debug(log_msg)
        expect(item).to be_nil
      end

      it 'does not output info message' do
        logger.info(log_msg)
        expect(item).to be_nil
      end

      it 'does not output warning message' do
        logger.warn(log_msg)
        expect(item).to be_nil
      end

      it 'outputs error message' do
        logger.error(log_msg)
        expect(item).to be_log_message(log_msg, 50)
      end

      it 'outputs fatal message' do
        logger.fatal(log_msg)
        expect(item).to be_log_message(log_msg, 60)
      end
    end

    context 'FATAL' do
      let(:log_msg) { 'log message' }
      before { logger.level = Logger::FATAL }

      it 'does not output debug message' do
        logger.debug(log_msg)
        expect(item).to be_nil
      end

      it 'does not output info message' do
        logger.info(log_msg)
        expect(item).to be_nil
      end

      it 'does not output warning message' do
        logger.warn(log_msg)
        expect(item).to be_nil
      end

      it 'does not output error message' do
        logger.error(log_msg)
        expect(item).to be_nil
      end

      it 'outputs fatal message' do
        logger.fatal(log_msg)
        expect(item).to be_log_message(log_msg, 60)
      end
    end
  end
end
