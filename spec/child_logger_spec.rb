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

  describe '#level' do
    let(:logger) { parent_logger.child }
    let(:log_msg) { 'log message' }

    shared_examples 'trace logging' do
      it 'outputs trace message' do
        logger.trace(log_msg)
        expect(item).to be_log_message(log_msg, 10)
      end

      it 'outputs debug message' do
        logger.debug(log_msg)
        expect(item).to be_log_message(log_msg, 20)
      end

      it 'is consistent with the methods severity allows' do
        expect(logger.trace?).to be_truthy
        expect(logger.debug?).to be_truthy
        expect(logger.info?).to be_truthy
        expect(logger.warn?).to be_truthy
        expect(logger.error?).to be_truthy
        expect(logger.fatal?).to be_truthy
      end
    end

    shared_examples 'debug logging' do
      it 'does not output trace message' do
        logger.trace(log_msg)
        expect(item).to be_nil
      end

      it 'outputs debug message' do
        logger.debug(log_msg)
        expect(item).to be_log_message(log_msg, 20)
      end

      it 'outputs info message' do
        logger.info(log_msg)
        expect(item).to be_log_message(log_msg, 30)
      end

      it 'is consistent with the methods severity allows' do
        expect(logger.trace?).to be_falsey
        expect(logger.debug?).to be_truthy
        expect(logger.info?).to be_truthy
        expect(logger.warn?).to be_truthy
        expect(logger.error?).to be_truthy
        expect(logger.fatal?).to be_truthy
      end
    end

    shared_examples 'info logging' do
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

      it 'is consistent with the methods severity allows' do
        expect(logger.trace?).to be_falsey
        expect(logger.debug?).to be_falsey
        expect(logger.info?).to be_truthy
        expect(logger.warn?).to be_truthy
        expect(logger.error?).to be_truthy
        expect(logger.fatal?).to be_truthy
      end
    end

    shared_examples 'warn logging' do
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

      it 'is consistent with the methods severity allows' do
        expect(logger.trace?).to be_falsey
        expect(logger.debug?).to be_falsey
        expect(logger.info?).to be_falsey
        expect(logger.warn?).to be_truthy
        expect(logger.error?).to be_truthy
        expect(logger.fatal?).to be_truthy
      end
    end

    shared_examples 'error logging' do
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

      it 'is consistent with the methods severity allows' do
        expect(logger.trace?).to be_falsey
        expect(logger.debug?).to be_falsey
        expect(logger.info?).to be_falsey
        expect(logger.warn?).to be_falsey
        expect(logger.error?).to be_truthy
        expect(logger.fatal?).to be_truthy
      end
    end

    shared_examples 'fatal logging' do
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

      it 'is consistent with the methods severity allows' do
        expect(logger.trace?).to be_falsey
        expect(logger.debug?).to be_falsey
        expect(logger.info?).to be_falsey
        expect(logger.warn?).to be_falsey
        expect(logger.error?).to be_falsey
        expect(logger.fatal?).to be_truthy
      end
    end

    shared_examples 'unknown logging' do
      it 'does not output fatal message' do
        logger.fatal(log_msg)
        expect(item).to be_nil
      end

      it 'outputs unknown message' do
        logger.unknown(log_msg)
        expect(item).to be_log_message(log_msg, 70)
      end

      it 'is consistent with the methods severity allows' do
        expect(logger.trace?).to be_falsey
        expect(logger.debug?).to be_falsey
        expect(logger.info?).to be_falsey
        expect(logger.warn?).to be_falsey
        expect(logger.error?).to be_falsey
        expect(logger.fatal?).to be_falsey
      end
    end

    context 'TRACE the same level as parent' do
      it_behaves_like 'trace logging' do
        before do
          parent_logger.level = Ougai::Logger::TRACE
          logger.level = Ougai::Logger::TRACE
        end
      end
    end

    context 'DEBUG above parent level' do
      it_behaves_like 'debug logging' do
        before do
          parent_logger.level = Ougai::Logger::TRACE
          logger.level = Ougai::Logger::DEBUG
        end
      end
    end

    context 'INFO above parent level' do
      it_behaves_like 'info logging' do
        before do
          parent_logger.level = Ougai::Logger::DEBUG
          logger.level = Ougai::Logger::INFO
        end
      end
    end

    context 'WARN above parent level' do
      it_behaves_like 'warn logging' do
        before do
          parent_logger.level = Ougai::Logger::INFO
          logger.level = Ougai::Logger::WARN
        end
      end
    end

    context 'ERROR above parent level' do
      it_behaves_like 'error logging' do
        before do
          parent_logger.level = Ougai::Logger::WARN
          logger.level = Ougai::Logger::ERROR
        end
      end
    end

    context 'FATAL above parent level' do
      it_behaves_like 'fatal logging' do
        before do
          parent_logger.level = Ougai::Logger::ERROR
          logger.level = Ougai::Logger::FATAL
        end
      end
    end

    context 'UNKNOWN the same level as parent' do
      it_behaves_like 'unknown logging' do
        before do
          parent_logger.level = Ougai::Logger::UNKNOWN
          logger.level = Ougai::Logger::UNKNOWN
        end
      end
    end

    context 'propagated from parent TRACE' do
      it_behaves_like 'trace logging' do
        before do
          parent_logger.level = Ougai::Logger::TRACE
        end
      end
    end

    context 'propagated from parent DEBUG' do
      it_behaves_like 'debug logging' do
        before do
          parent_logger.level = Ougai::Logger::DEBUG
        end
      end
    end

    context 'propagated from parent INFO' do
      it_behaves_like 'info logging' do
        before do
          parent_logger.level = Ougai::Logger::INFO
        end
      end
    end

    context 'propagated from parent WARN' do
      it_behaves_like 'warn logging' do
        before do
          parent_logger.level = Ougai::Logger::WARN
        end
      end
    end

    context 'propagated from parent ERROR' do
      it_behaves_like 'error logging' do
        before do
          parent_logger.level = Ougai::Logger::ERROR
        end
      end
    end

    context 'propagated from parent FATAL' do
      it_behaves_like 'fatal logging' do
        before do
          parent_logger.level = Ougai::Logger::FATAL
        end
      end
    end

    context 'propagated from parent UNKNOWN' do
      it_behaves_like 'unknown logging' do
        before do
          parent_logger.level = Ougai::Logger::UNKNOWN
        end
      end
    end

    context 'set a level once, set nil' do
      before do
        parent_logger.level = Ougai::Logger::WARN
        logger.level = Ougai::Logger::INFO
      end

      it 'propagates from parent level' do
        expect(logger.level).to eq Ougai::Logger::INFO
        logger.level = nil
        expect(logger.level).to eq Ougai::Logger::WARN
      end
    end

    context 'set wrong name level' do
      it 'throws ArgumentErrror' do
        expect { logger.level = :wrong_level }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#sev_threshold' do
    let(:logger) { parent_logger.child }

    it 'is the alias of level' do
      logger.sev_threshold = Ougai::Logger::INFO
      expect(logger.sev_threshold).to eq Ougai::Logger::INFO
      expect(logger.level).to eq Ougai::Logger::INFO

      logger.level = :trace
      expect(logger.sev_threshold).to eq Ougai::Logger::TRACE
      expect(logger.level).to eq Ougai::Logger::TRACE

      logger.sev_threshold = 'unknown'
      expect(logger.sev_threshold).to eq Ougai::Logger::UNKNOWN
      expect(logger.level).to eq Ougai::Logger::UNKNOWN
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
        parent_logger.with_fields = { tag: 'parent', tags: ['parent'], event: { module: 'core' } }
      end

      let(:logger) { parent_logger.child(tag: 'child', tags: ['child'], event: { dataset: 'core.child' }) }
      let(:grand_logger) { logger.child(tag: 'grandchild', tags: ['grandchild'], event: { action: 'log-action' }) }

      it 'outputs with all merged fields' do
        grand_logger.info('Hi', foo: 3)
        logger.info(log_msg, foo: 2)
        parent_logger.info(parent_log_msg, foo: 10, event: { module: 'service' })
        parent_logger.info('Good evening!', foo: 11, event: { duration: 150 })

        expect(items[0]).to be_log_message('Hi', log_level)
        expect(items[0]).to include(
          tag: 'grandchild',
          tags: ['parent', 'child', 'grandchild'],
          foo: 3,
          event: { module: 'core', dataset: 'core.child', action: 'log-action' }
        )

        expect(items[1]).to be_log_message(log_msg, log_level)
        expect(items[1]).to include(
          tag: 'child',
          tags: ['parent', 'child'],
          foo: 2,
          event: { module: 'core', dataset: 'core.child' }
        )

        expect(items[2]).to be_log_message(parent_log_msg, log_level)
        expect(items[2]).to include(tag: 'parent', tags: ['parent'], foo: 10, event: { module: 'service' })
        expect(items[3]).to be_log_message('Good evening!', log_level)
        expect(items[3]).to include(tag: 'parent', tags: ['parent'], foo: 11, event: { module: 'core', duration: 150 })
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

  describe '#before_log' do
    let(:logger) { parent_logger.child }
    let(:log_msg) { 'before_log test' }

    before do
      parent_logger.level = Logger::INFO
    end

    context 'child logger to be set before_log' do
      before do
        logger.before_log = lambda do |data|
          data[:context_id] = 123
        end
      end

      it 'outputs the field to be added in before_log' do
        logger.info(log_msg)
        expect(item).to be_log_message(log_msg, 30)
        expect(item).to include(context_id: 123)
      end
    end

    context 'parent logger to be set before_log' do
      before do
        parent_logger.before_log = lambda do |data|
          data[:context_id] = 12345
        end
      end

      it 'outputs the field to be added in before_log' do
        logger.info(log_msg)
        expect(item).to be_log_message(log_msg, 30)
        expect(item).to include(context_id: 12345)
      end
    end

    context 'both child logger and parent logger to be set before_log' do
      before do
        logger.before_log = lambda do |data|
          data[:context_id] = 67890
          data[:context_name] = 'sub'
        end
        parent_logger.before_log = lambda do |data|
          data[:context_id] = 12345
        end
      end

      it 'outputs the fields to be added in each before_log' do
        logger.info(log_msg)
        expect(item).to be_log_message(log_msg, 30)
        expect(item).to include(context_id: 12345) # parent
        expect(item).to include(context_name: 'sub') # child
      end
    end
  end

  describe '#child' do
    let!(:root) { double('root logger') }

    context 'when the class is original' do
      subject!(:org_instance) { described_class.new(root, {}) }

      it 'returns an instance of the same class' do
        expect(org_instance.child).to be_an_instance_of(described_class)
      end
    end

    context 'when the class is sub-class' do
      subject!(:sc_instance) { Class.new(described_class).new(root, {}) }

      it 'returns an instance of the child_class' do
        expect(sc_instance.child).to be_an_instance_of(sc_instance.class)
      end
    end

    context 'block is given' do
      let!(:fields) { double('fields') }

      subject { described_class.new(root, {}) }

      it 'yields child logger' do
        subject.child(fields) do |cl|
          expect(cl.instance_variable_get(:@parent)).to eq(subject)
          expect(cl.instance_variable_get(:@with_fields)).to eq(fields)
        end
      end
    end
  end
end
