require 'spec_helper'

describe Ougai::Formatters::Base do
  subject { described_class.new(app_name, hostname) }

  context 'default' do
    let (:app_name) { nil }
    let (:hostname) { nil }

    it 'has datetime format default ISO8601' do
      expect(subject.datetime_format).to match(/^\%FT\%T\.\%3N(Z|\%\:z)$/)
    end

    it 'has datetime_format accessor' do
      subject.datetime_format = '%I:%M:%S %p'
      expect(subject.datetime_format).to eq('%I:%M:%S %p')

      # revert default format by to set nil
      subject.datetime_format = nil
      expect(subject.datetime_format).to match(/^\%FT\%T\.\%3N(Z|\%\:z)$/)
    end
  end

  context 'without arguments and hostname contains a UTF-8 char' do
    let (:app_name) { nil }
    let (:hostname) { nil }

    it 'has default app_name and default hostname' do
      myhostname = "Taro\xE2\x80\x99s-MacBook".force_encoding('ASCII-8BIT')
      allow(Socket).to receive(:gethostname).and_return(myhostname)
      expect(subject.app_name).to eq('rspec')
      expect(subject.hostname).to eq("Taro’s-MacBook")
    end
  end

  context 'with app_name' do
    let (:app_name) { 'myapp' }
    let (:hostname) { nil }

    it 'has specified app_name and default hostname' do
      myhostname = "Hanako's PC".encode('ASCII-8BIT')
      allow(Socket).to receive(:gethostname).and_return(myhostname)
      expect(subject.app_name).to eq('myapp')
      expect(subject.hostname).to eq("Hanako's PC")
    end
  end

  context 'with hostname' do
    let (:app_name) { nil }
    let (:hostname) { 'myhost' }

    it 'has default app_name and specified hostname' do
      expect(subject.app_name).to eq('rspec')
      expect(subject.hostname).to eq('myhost')
    end
  end

  context 'with app_name and hostname' do
    let (:app_name) { 'myapp' }
    let (:hostname) { 'myhost' }

    it 'has specified app_name and specified hostname' do
      expect(subject.app_name).to eq('myapp')
      expect(subject.hostname).to eq('myhost')
    end
  end
end
