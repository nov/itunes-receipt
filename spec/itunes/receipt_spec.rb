require 'spec_helper'

describe Itunes::Receipt do

  describe '.verify!' do
    it 'should support sandbox mode' do
      sandbox_mode do
        lambda do
          Itunes::Receipt.verify! 'receipt-data'
        end.should post_to Itunes::ENDPOINT[:sandbox]
      end
    end

    context 'when invalid' do
      before do
        fake_json :invalid
      end

      it 'should raise VerificationFailed' do
        lambda do
          Itunes::Receipt.verify! 'invalid'
        end.should raise_error Itunes::Receipt::VerificationFailed
      end
    end

    context 'when valid' do
      before do
        fake_json :valid
      end

      it 'should return valid Receipt instance' do
        receipt = Itunes::Receipt.verify! 'valid'
        receipt.should be_instance_of Itunes::Receipt
        receipt.quantity == 1
        receipt.product_id.should == 'com.cerego.iknow.30d'
        receipt.transaction_id.should == '1000000001479608'
        receipt.purchase_date.should == Time.utc(2011, 2, 17, 6, 20, 57)
        receipt.bid.should == 'com.cerego.iknow'
        receipt.bvrs.should == '1.0'
        receipt.original.quantity.should be_nil
        receipt.original.transaction_id.should == '1000000001479608'
        receipt.original.purchase_date.should == Time.utc(2011, 2, 17, 6, 20, 57)

        # Those attributes are not returned from iTunes Connect Sandbox
        receipt.app_item_id.should be_nil
        receipt.version_external_identifier.should be_nil
      end
    end
  end
end