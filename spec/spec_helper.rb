require 'timecop'
require 'simplecov'
SimpleCov.start do
  add_filter "/spec/"
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ougai'

RSpec.shared_examples 'JSON formatter#initialize' do
  describe '#initialize' do
    let(:app_name) { 'dummy app name' }
    let(:hostname) { 'dummyhost' }

    subject { described_class.new(*arguments) }

    context 'with app_name' do
      let!(:arguments) { [app_name] }

      it 'creates an instance with valid app_name and hostname' do
        expect(subject.app_name).to eq(app_name)
        expect(subject.hostname).to eq(Socket.gethostname.force_encoding('UTF-8'))
      end
    end

    context 'with app_name and hostname' do
      let!(:arguments) { [app_name, hostname] }

      it 'creates an instance with valid app_name and hostname' do
        expect(subject.app_name).to eq(app_name)
        expect(subject.hostname).to eq(hostname)
      end
    end
  end
end
