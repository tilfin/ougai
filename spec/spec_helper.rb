require 'timecop'
require 'simplecov'
SimpleCov.start do
  add_filter "/spec/"
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ougai'

RSpec.shared_examples 'formatter#initialize' do |params|
    describe '#initialize' do
    let(:app_name) { 'dummy app name' }
    let(:hostname) { 'dummyhost' }
    let(:options) { params[:options] }

    subject { described_class.new(*arguments) }

    context 'with app_name' do
      let!(:arguments) { [app_name] }

      it 'creates an instance with valid app_name and hostname' do
        expect(subject.app_name).to eq(app_name)
        expect(subject.hostname).to eq(Socket.gethostname.force_encoding('UTF-8'))
        params[:default_opts].each do |key, val|
          expect(subject.send(key)).to eq(val)
        end
      end
    end

    context 'with options' do
      let!(:arguments) { [options] }

      it 'creates an instance with valid values for attributes' do
        expect(subject.app_name).to eq('rspec')
        expect(subject.hostname).to eq(Socket.gethostname.force_encoding('UTF-8'))
        options.each do |key, val|
          expect(subject.send(key)).to eq(val)
        end
      end
    end

    context 'with app_name and hostname' do
      let!(:arguments) { [app_name, hostname] }

      it 'creates an instance with valid app_name and hostname' do
        expect(subject.app_name).to eq(app_name)
        expect(subject.hostname).to eq(hostname)
        params[:default_opts].each do |key, val|
          expect(subject.send(key)).to eq(val)
        end
      end
    end

    context 'with app_name and options' do
      let!(:arguments) { [app_name, options] }

      it 'creates an instance with valid values for attributes' do
        expect(subject.app_name).to eq(app_name)
        expect(subject.hostname).to eq(Socket.gethostname.force_encoding('UTF-8'))
        options.each do |key, val|
          expect(subject.send(key)).to eq(val)
        end
      end
    end

    context 'with app_name, hostname and options' do
      let!(:arguments) { [app_name, hostname, options] }

      it 'creates an instance with valid values for attributes' do
        expect(subject.app_name).to eq(app_name)
        expect(subject.hostname).to eq(hostname)
        options.each do |key, val|
          expect(subject.send(key)).to eq(val)
        end
      end
    end
  end
end
