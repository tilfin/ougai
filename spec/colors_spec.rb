require 'spec_helper'
require 'ougai/colors'

describe Ougai::Colors do

  describe '#color_text' do
    let(:dummy_text) { 'some dummy text' }
  
    context 'color is nil' do
      it 'raw text is returned' do
        uncolored_text = Ougai::Colors.color_text(nil, dummy_text)
        expect(uncolored_text).to eq(dummy_text)
      end
    end

    context 'color is provided' do
      it 'text is properly colored' do
        colored_text = Ougai::Colors.color_text(Ougai::Colors::RED, dummy_text)
        expect(colored_text).to eq(Ougai::Colors::RED + dummy_text + Ougai::Colors::RESET)
      end
    end
  end

end
