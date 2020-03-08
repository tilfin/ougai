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
        && err[:stack].include?('<main>')
    end
  end

  let(:io) { StringIO.new }
  let(:logger) { described_class.new(io) }

  let(:item) do
    log_str = io.string
    begin
      JSON.parse(log_str, symbolize_names: true)
    rescue Exception
      nil
    end 
  end

  class Dummy
    def to_hash
      { foo: 1 }
    end
  end

  describe '.new' do
    context 'if formatter argument is not specified' do
      it 'sets Bunyan to formatter attribute' do
        expect(logger.formatter).to be_an(Ougai::Formatters::Bunyan)
      end
    end

    if RUBY_VERSION > '2.4'
      context 'if formatter argument is specified' do
        it 'sets it to formatter attribute' do
          a_formatter = Ougai::Formatters::Readable.new
          a_logger = described_class.new(io, formatter: a_formatter)
          expect(a_logger.formatter).to eq a_formatter
        end
      end
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

      it 'outputs valid with fields' do
        logger.with_fields = { coreField1: 123, core_field2: 'core', 'core_field3' => 456  }
        logger.send(method, { msg: log_msg, data_id: 109, action: 'do' })
        expect(item).to be_log_message(log_msg, log_level)
        expect(item).to include_data(data_id: 109, action: 'do', coreField1: 123, core_field2: 'core', core_field3: 456)
      end

      it 'outputs valid with fields overridden' do
        logger.with_fields = { core_field1: 'original', core_field2: 'original', err: 'original' }
        logger.send(method, { msg: log_msg, data_id: 110, action: 'do', core_field1: 'override' })
        expect(item).to be_log_message(log_msg, log_level)
        expect(item).to include_data(data_id: 110, action: 'do', core_field1: 'override', core_field2: 'original', err: 'original')
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

    context 'with data that can respond to_hash' do
      it 'outputs valid' do
        logger.send(method, Dummy.new)
        expect(item).to be_log_message('No message', log_level)
        expect(item).to include_data(foo: 1)
      end
    end

    context 'with data that cannot respond to_hash' do
      it '(array) outputs valid' do
        logger.send(method, ['bar', 2])
        expect(item).to be_log_message('No message', log_level)
        expect(item).to include_data(data: ['bar', 2])
      end

      it '(number) outputs valid' do
        logger.send(method, 999)
        expect(item).to be_log_message('No message', log_level)
        expect(item).to include_data(data: 999)
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

      it 'outputs valid overridden err field' do
        logger.with_fields = { err: 'original' }
        begin
          raise StandardError, 'errmsg2'
        rescue => ex
          logger.send(method, log_msg, ex)
        end

        expect(item).to include_error('errmsg2')
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

    context 'without arguments' do
      it 'outputs only default message' do
        logger.send(method)
        expect(item).to be_log_message('No message', log_level)
      end
    end
  end

  describe '#trace' do
    let(:log_level) { 10 }
    let(:log_msg) { 'trace message' }
    let(:method) { 'trace' }

    before { logger.level = :trace }

    it_behaves_like 'log'

    it 'is consistent with the methods severity allows' do
      expect(logger.trace?).to be_truthy
      expect(logger.debug?).to be_truthy
      expect(logger.info?).to be_truthy
      expect(logger.warn?).to be_truthy
      expect(logger.error?).to be_truthy
      expect(logger.fatal?).to be_truthy
    end
  end

  describe '#debug' do
    let(:log_level) { 20 }
    let(:log_msg) { 'debug message' }
    let(:method) { 'debug' }

    it_behaves_like 'log'

    it 'is consistent with the methods severity allows' do
      expect(logger.trace?).to be_falsey
      expect(logger.debug?).to be_truthy
    end
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

      it 'outputs unknown message' do
        logger.unknown(log_msg)
        expect(item).to be_log_message(log_msg, 70)
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

      it 'outputs unknown message' do
        logger.unknown(log_msg)
        expect(item).to be_log_message(log_msg, 70)
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

      it 'outputs unknown message' do
        logger.unknown(log_msg)
        expect(item).to be_log_message(log_msg, 70)
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

      it 'outputs unknown message' do
        logger.unknown(log_msg)
        expect(item).to be_log_message(log_msg, 70)
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

      it 'outputs unknown message' do
        logger.unknown(log_msg)
        expect(item).to be_log_message(log_msg, 70)
      end
    end

    context 'UNKNOWN' do
      let(:log_msg) { 'log message' }
      before { logger.level = Logger::UNKNOWN }

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

      it 'does not output fatal message' do
        logger.fatal(log_msg)
        expect(item).to be_nil
      end

      it 'outputs unknown message' do
        logger.unknown(log_msg)
        expect(item).to be_log_message(log_msg, 70)
      end
    end
  end

  describe '#before_log' do
    let(:log_msg) { 'before_log test' }

    context 'set context data' do
      before do
        logger.level = Logger::INFO
        logger.before_log = lambda do |data|
          data.data[:context_id] = 123
        end
      end

      it 'outputs with context data' do
        logger.info(log_msg)
        expect(item).to be_log_message(log_msg, 30)
        expect(item).to include(context_id: 123)
      end
    end

    context 'cancelling log' do
      before do
        logger.level = Logger::INFO
        logger.before_log = lambda do |data|
          false
        end
      end

      it 'outputs none' do
        logger.info(log_msg)
        expect(item).to be_nil
      end
    end
  end

  describe '#broadcast' do
    let(:log_msg) { 'broadcast test message' }

    let(:another_io) { StringIO.new }
    let(:another_logger) { described_class.new(another_io) }

    let(:another_item) do
      log_str = another_io.string
      begin
        JSON.parse(log_str, symbolize_names: true)
      rescue Exception
        nil
      end 
    end

    before do
      logger.extend Ougai::Logger.broadcast(another_logger)
    end

    context 'another logger level is the same as original one' do
      before do
        logger.level = Logger::INFO # propagate severity to another one
      end

      it 'does not output trace log on both loggers' do
        logger.trace(log_msg, foo: 0)
        expect(item).to be_nil
        expect(another_item).to be_nil
      end

      it 'does not output debug log on both loggers' do
        logger.debug(log_msg, foo: 1)
        expect(item).to be_nil
        expect(another_item).to be_nil
      end

      it 'does not output debug log with block on both loggers' do
        logger.debug { [log_msg, foo: 1] }
        expect(item).to be_nil
        expect(another_item).to be_nil
      end

      it 'outputs info log on both loggers' do
        logger.info(log_msg, foo: 2)
        expect(item).to be_log_message(log_msg, 30)
        expect(item).to include_data(foo: 2)
        expect(another_item).to be_log_message(log_msg, 30)
        expect(another_item).to include_data(foo: 2)
      end

      it 'outputs info log with block on both loggers' do
        logger.info { [log_msg, { foo: 2 }] }
        expect(item).to be_log_message(log_msg, 30)
        expect(item).to include_data(foo: 2)
        expect(another_item).to be_log_message(log_msg, 30)
        expect(another_item).to include_data(foo: 2)
      end

      it 'outputs warning log on both loggers' do
        logger.warn(log_msg)
        expect(item).to be_log_message(log_msg, 40)
        expect(another_item).to be_log_message(log_msg, 40)
      end
    end

    context 'another logger level is lower than original one' do
      before do
        logger.level = Logger::DEBUG
        another_logger.level = :trace
      end

      it 'does not output trace log on both loggers' do
        logger.trace(log_msg)
        expect(item).to be_nil
        expect(another_item).to be_log_message(log_msg, 10)
      end

      it 'outputs debug log on both loggers' do
        logger.debug(log_msg)
        expect(item).to be_log_message(log_msg, 20)
        expect(another_item).to be_log_message(log_msg, 20)
      end
    end

    context 'another logger level is greater than original one' do
      before do
        logger.level = Logger::INFO
        another_logger.level = Logger::WARN
      end

      it 'outputs info log on only original logger' do
        logger.info(log_msg)
        expect(item).to be_log_message(log_msg, 30)
        expect(another_item).to be_nil
      end

      it 'outputs warning log on both loggers' do
        logger.warn(log_msg)
        expect(item).to be_log_message(log_msg, 40)
        expect(another_item).to be_log_message(log_msg, 40)
      end
    end

    it 'close both loogers' do
      logger.close
      expect(io.closed?).to be_truthy
      expect(another_io.closed?).to be_truthy
    end
  end

  describe '.child_class' do
    let!(:org_logger_cls) { described_class }
    let!(:sc_logger_cls) { Class.new(described_class) }

    context 'when Logger class is original' do
      subject { described_class.child_class }

      it { is_expected.to eq(Ougai::ChildLogger) }
    end

    context 'when Logger class is sub-class' do
      subject { Class.new(described_class).child_class }

      it 'returns sub-class of Ougai::ChildLogger' do
        expect(subject).not_to eq(Ougai::ChildLogger)
        expect(subject.superclass).to eq(Ougai::ChildLogger)
      end
    end
  end

  describe '#child' do
    context 'when Logger class is original' do
      subject!(:org_instance) { described_class.new(STDOUT) }

      it 'returns ChildLogger instance' do
        expect(org_instance.child).to be_an_instance_of(Ougai::ChildLogger)
      end
    end

    context 'when Logger class is sub-class' do
      subject!(:sc_instance) { Class.new(described_class).new(STDOUT) }

      it 'returns an instance of the child_class' do
        expect(sc_instance.child).to be_an_instance_of(sc_instance.class.child_class)
      end
    end

    context 'block is given' do
      let!(:fields) { double('fields') }

      subject { described_class.new(STDOUT) }

      it 'yields child logger' do
        subject.child(fields) do |cl|
          expect(cl.instance_variable_get(:@parent)).to eq(subject)
          expect(cl.instance_variable_get(:@with_fields)).to eq(fields)
        end
      end
    end
  end
end
