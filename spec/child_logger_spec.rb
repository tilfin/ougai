require 'spec_helper'
require 'stringio'
require 'json'

describe Ougai::ChildLogger do
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

  let(:io) { StringIO.new }
  let(:parent_logger) { Ougai::Logger.new(io) }

  let(:items) do
    io.rewind
    io.readlines.map do |line|
      JSON.parse(line.chomp, symbolize_names: true)
    end
  end

  let(:item) {
    items[0]
  }

  describe '#level propagated from parent one' do
    let(:logger) { parent_logger.child }

    context 'DEBUG' do
      let(:log_msg) { 'log message' }
      before { parent_logger.level = Logger::DEBUG }

      it 'outputs debug message' do
        logger.debug(log_msg)
        expect(item).to be_log_message(log_msg, 20)
      end

      it 'outputs info message' do
        logger.info(log_msg)
        expect(item).to be_log_message(log_msg, 30)
      end
    end

    context 'INFO' do
      let(:log_msg) { 'log message' }
      before { parent_logger.level = Logger::INFO }

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
    end

    context 'WARN' do
      let(:log_msg) { 'log message' }
      before { parent_logger.level = Logger::WARN }

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
    end

    context 'ERROR' do
      let(:log_msg) { 'log message' }
      before { parent_logger.level = Logger::ERROR }

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
      before { parent_logger.level = Logger::FATAL }

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
      before { parent_logger.level = Logger::UNKNOWN }

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

  describe '#chain' do
    let(:log_level) { 30 }
    let(:log_msg) { 'log message' }
    let(:parent_log_msg) { 'parent log message' }

    context 'parent with fields, child with fields' do
      before do
        parent_logger.with_fields = { foo: 1, pos: 'parent' }
      end

      let(:logger) { parent_logger.child(bar: '1', pos: 'child') }

      it 'outputs with merged parent and child fields' do
        logger.info(log_msg)
        parent_logger.info(parent_log_msg)

        expect(items[0]).to be_log_message(log_msg, log_level)
        expect(items[0]).to include(foo: 1, bar: '1', pos: 'child')
        expect(items[1]).to be_log_message(parent_log_msg, log_level)
        expect(items[1]).to include(foo: 1, pos: 'parent')
        expect(items[1]).not_to include(:bar)
      end

      context 'after updating with_fieldses of parent and child' do
        before do
          parent_logger.with_fields = { foo: 11 }
          logger.with_fields = { bar: '11' }
        end
 
        it 'outputs with child fields' do
          logger.info(log_msg)
          parent_logger.info(parent_log_msg)

          expect(items[0]).to be_log_message(log_msg, log_level)
          expect(items[0]).to include(foo: 11, bar: '11')
          expect(items[0]).not_to include(:pos)
          expect(items[1]).to be_log_message(parent_log_msg, log_level)
          expect(items[1]).to include(foo: 11)
          expect(items[1]).not_to include(:bar, :pos)
        end
      end
    end

    context 'parent with fields, child without fields' do
      before do
        parent_logger.with_fields = { foo: 2, pos: 'parent' }
      end

      let(:logger) { parent_logger.child }

      it 'output valid' do
        logger.info(log_msg)
        parent_logger.info(parent_log_msg)

        expect(items[0]).to be_log_message(log_msg, log_level)
        expect(items[0]).to include(foo: 2, pos: 'parent')
        expect(items[1]).to be_log_message(parent_log_msg, log_level)
        expect(items[1]).to include(foo: 2, pos: 'parent')
      end

      context 'after updating parent logger with_fields' do
        before do
          parent_logger.with_fields = { foo: 22 }
        end
 
        it 'output with new parent fields' do
          logger.info(log_msg)
          parent_logger.info(parent_log_msg)

          expect(items[0]).to be_log_message(log_msg, log_level)
          expect(items[0]).to include(foo: 22)
          expect(items[0]).not_to include(:pos)
          expect(items[1]).to be_log_message(parent_log_msg, log_level)
          expect(items[1]).to include(foo: 22)
          expect(items[1]).not_to include(:pos)
        end
      end
    end

    context 'parent without fields, child with fields' do
      before do
        parent_logger.with_fields = {}
      end

      let(:logger) { parent_logger.child(bar: '3', pos: 'child') }

      it 'output valid' do
        logger.info(log_msg)
        parent_logger.info(parent_log_msg)

        expect(items[0]).to be_log_message(log_msg, log_level)
        expect(items[0]).to include(bar: '3', pos: 'child')
        expect(items[1]).to be_log_message(parent_log_msg, log_level)
        expect(items[1]).not_to include(:bar, :pos)
      end

      context 'after updating child logger with_fields' do
        before do
          logger.with_fields = { bar: '33' }
        end
 
        it 'output valid' do
          logger.info(log_msg)
          parent_logger.info(parent_log_msg)

          expect(items[0]).to be_log_message(log_msg, log_level)
          expect(items[0]).to include(bar: '33')
          expect(items[0]).not_to include(:pos)
          expect(items[1]).to be_log_message(parent_log_msg, log_level)
          expect(items[1]).not_to include(:bar, :pos)
        end
      end
    end

    context 'grandchild logger' do
      before do
        parent_logger.with_fields = { tag: 'parent', tags: ['parent'] }
      end

      let(:logger) { parent_logger.child(tag: 'child', tags: ['child']) }
      let(:grand_logger) { logger.child(tag: 'grandchild', tags: ['grandchild']) }

      it 'outputs with all merged fields' do
        grand_logger.info('Hi', foo: 3)
        logger.info(log_msg, foo: 2)
        parent_logger.info(parent_log_msg, foo: 10)
        parent_logger.info('Good evening!', foo: 11)

        expect(items[0]).to be_log_message('Hi', log_level)
        expect(items[0]).to include(tag: 'grandchild', tags: ['parent', 'child', 'grandchild'], foo: 3)

        expect(items[1]).to be_log_message(log_msg, log_level)
        expect(items[1]).to include(tag: 'child', tags: ['parent', 'child'], foo: 2)

        expect(items[2]).to be_log_message(parent_log_msg, log_level)
        expect(items[2]).to include(tag: 'parent', tags: ['parent'], foo: 10)
        expect(items[3]).to be_log_message('Good evening!', log_level)
        expect(items[3]).to include(tag: 'parent', tags: ['parent'], foo: 11)
      end

      context 'after updating child logger with_fields' do
        before do
          logger.with_fields = { bar: '33' }
        end
 
        it 'outputs with child fields' do
          logger.info(log_msg)
          expect(items[0]).to be_log_message(log_msg, log_level)
          expect(items[0]).to include(bar: '33')
          expect(items[0]).not_to include(:pos)
        end
      end
    end
  end
end
