require 'spec_helper'

describe Itunes do

  describe 'the module' do
    before do
      Itunes.shared_secret = nil
    end

    context 'sandbox' do
      it 'should be production by default' do
        Itunes.sandbox?.should be_false
      end

      it 'should be settable' do
        Itunes.sandbox!
        Itunes.sandbox?.should be_true
      end
    end

    context 'shared_secret' do
      it 'should allow setting' do
        Itunes.shared_secret.should be_nil
        Itunes.shared_secret = 'hey'
        Itunes.shared_secret.should == 'hey'
      end
    end

  end
end
