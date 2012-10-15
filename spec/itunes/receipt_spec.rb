require 'spec_helper'

describe Itunes::Receipt do

  describe '.verify!' do
    it 'should support sandbox mode' do
      sandbox_mode do
        expect do
          Itunes::Receipt.verify! 'receipt-data'
        end.to post_to Itunes::ENDPOINT[:sandbox]
      end
    end

    it 'should not pass along shared secret if not set' do
      fake_json(:invalid)
      Itunes.shared_secret = nil
      RestClient.should_receive(:post).with(Itunes.endpoint, {:'receipt-data' => 'receipt-data'}.to_json).and_return("{}")
      expect do
        Itunes::Receipt.verify! 'receipt-data'
      end.to raise_error Itunes::Receipt::VerificationFailed
    end

    it 'should pass along shared secret if set' do
      fake_json(:invalid)
      Itunes.shared_secret = 'hey'
      RestClient.should_receive(:post).with(Itunes.endpoint, {:'receipt-data' => 'receipt-data', :password => 'hey'}.to_json).and_return("{}")
      expect do
        Itunes::Receipt.verify! 'receipt-data'
      end.to raise_error Itunes::Receipt::VerificationFailed
    end

    context 'when invalid' do
      before do
        fake_json :invalid
      end

      it 'should raise VerificationFailed' do
        expect do
          Itunes::Receipt.verify! 'invalid'
        end.to raise_error Itunes::Receipt::VerificationFailed
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
        receipt.expires_date.should be_nil
        receipt.receipt_data.should be_nil

        # Those attributes are not returned from iTunes Connect Sandbox
        receipt.app_item_id.should be_nil
        receipt.version_external_identifier.should be_nil
      end
    end

    context 'when autorenew subscription' do
      before do
        fake_json :autorenew_subscription
      end

      it 'should return valid Receipt instance for autorenew subscription' do
        original_transaction_id = '1000000057005439'
        original_purchase_date = Time.utc(2012, 10, 11, 14, 45, 40)
        receipt = Itunes::Receipt.verify! 'autorenew_subscription'
        receipt.should be_instance_of Itunes::Receipt
        receipt.quantity == 1
        receipt.product_id.should == 'com.notkeepingitreal.fizzbuzz.subscription.autorenew1m'
        receipt.transaction_id.should == '1000000055076747'
        receipt.purchase_date.should == Time.utc(2012, 10, 13, 19, 40, 8)
        receipt.bid.should == 'com.notkeepingitreal.fizzbuzz'
        receipt.bvrs.should == '1.0'
        receipt.original.quantity.should be_nil
        receipt.original.transaction_id.should == original_transaction_id
        receipt.original.purchase_date.should == original_purchase_date
        receipt.expires_date.should == Time.utc(2012, 10, 13, 19, 45, 8)
        receipt.receipt_data.should be_nil

        # Those attributes are not returned from iTunes Connect Sandbox
        receipt.app_item_id.should be_nil
        receipt.version_external_identifier.should be_nil

        latest = receipt.latest
        latest.should be_instance_of Itunes::Receipt
        latest.quantity == 1
        latest.product_id.should == 'com.notkeepingitreal.fizzbuzz.subscription.autorenew1m'
        latest.transaction_id.should == '1000000052076747'
        latest.purchase_date.should == Time.utc(2012, 10, 13, 19, 40, 8)
        latest.expires_date.should == Time.utc(2012, 10, 13, 19, 50, 8) # five minutes after the "old" receipt
        latest.bid.should == 'com.notkeepingitreal.fizzbuzz'
        latest.bvrs.should == '1.0'
        latest.original.quantity.should be_nil
        latest.original.transaction_id.should == original_transaction_id
        latest.original.purchase_date.should == original_purchase_date
        latest.receipt_data.should == 'junk='
       
        # Those attributes are not returned from iTunes Connect Sandbox
        latest.app_item_id.should be_nil
        latest.version_external_identifier.should be_nil
      end
    end
  end
end
