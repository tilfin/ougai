require 'spec_helper'

describe Ougai::Formatters::Readable do
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

  context 'when severity is DEBUG' do
    subject { described_class.new.call('DEBUG', Time.now, nil, data) }

    it 'includes valid strings' do
      expect(subject).to include("\e[0;37mDEBUG\e[0m: Log Message!")
      expect(subject.gsub(/\e\[([;\d]+)?m/, '')).to include(':status => 200')
    end
  end

  context 'when severity is INFO' do
    subject { described_class.new.call('INFO', Time.now, nil, data) }

    it 'includes valid strings' do
      expect(subject).to include("\e[0;36mINFO\e[0m: Log Message!")
      expect(subject.gsub(/\e\[([;\d]+)?m/, '')).to include(':method => "GET"')
    end
  end

  context 'when severity is WARN' do
    subject { described_class.new.call('WARN', Time.now, nil, data) }

    it 'includes valid strings' do
      expect(subject).to include("\e[0;33mWARN\e[0m: Log Message!")
      expect(subject.gsub(/\e\[([;\d]+)?m/, '')).to include(':path => "/"')
    end
  end

  context 'when severity is ERROR' do
    subject { described_class.new.call('ERROR', Time.now, nil, data.merge({ err: err })) }

    it 'includes valid strings' do
      expect(subject).to include("\e[0;31mERROR\e[0m: Log Message!")
      expect(subject.gsub(/\e\[([;\d]+)?m/, '')).to include('DummyError (it is dummy.):')
    end
  end

  context 'when severity is FATAL' do
    subject { described_class.new.call('FATAL', Time.now, nil, { msg: 'TheEnd', err: err }) }
    it 'includes valid strings' do
      expect(subject).to include("\e[0;35mFATAL\e[0m: TheEnd")
      expect(subject.gsub(/\e\[([;\d]+)?m/, '')).to include("error1.rb\n  error2.rb")
    end
  end
end
