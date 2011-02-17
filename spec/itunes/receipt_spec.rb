require 'spec_helper'

describe Itunes::Receipt do

  describe '.verify!' do
    it 'should support sandbox mode' do
      lambda do
        Itunes::Receipt.verify! 'receipt-data'
      end.should post_to Itunes::ENDPOINT[:sandbox]
    end

  end



end