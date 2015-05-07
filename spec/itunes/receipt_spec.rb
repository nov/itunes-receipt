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

      context 'due to a sandbox receipt reply' do
        before do
          fake_json :sandboxed
          sandbox_mode do
            fake_json :valid
          end
        end

        context 'when sandbox receipt accepted explicitly' do
          it 'should try and verify the receipt against the sandbox ' do
            receipt = Itunes::Receipt.verify! 'sandboxed', :allow_sandbox_receipt
            expect(receipt).to be_an_instance_of(Itunes::Receipt)
            expect(receipt.transaction_id).to eq '1000000001479608'
            expect(receipt.itunes_env).to eq :sandbox
            expect(receipt.sandbox?).to eq true
          end
        end

        context 'otherwise' do
          it 'should raise SandboxReceiptReceived exception' do
            expect do
              Itunes::Receipt.verify! 'sandboxed'
            end.to raise_error Itunes::Receipt::SandboxReceiptReceived
          end
        end
      end
    end

    context 'when valid' do
      before do
        fake_json :valid
      end

      it 'should not be an application receipt' do
        receipt = Itunes::Receipt.verify! 'valid_application'
        receipt.application_receipt?.should == false
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
        receipt.itunes_env.should == :production

        # Those attributes are not returned from iTunes Connect Sandbox
        receipt.app_item_id.should be_nil
        receipt.version_external_identifier.should be_nil
      end
    end

    context 'when application receipt' do
      before do
        fake_json :valid_application
      end

      it 'should be an application receipt' do
        receipt = Itunes::Receipt.verify! 'valid_application'
        receipt.application_receipt?.should == true
      end

      it 'should return valid Receipt instance' do
        receipt = Itunes::Receipt.verify! 'valid_application'
        receipt.bundle_id.should == 'com.tekkinnovations.fars'
        receipt.application_version.should == '1.80'
        receipt.in_app.should be_instance_of Array

        receipt.in_app[0].should be_instance_of Itunes::Receipt
        receipt.in_app[0].quantity.should == 1
        receipt.in_app[0].product_id.should == "com.tekkinnovations.fars.subscription.6.months"
        receipt.in_app[0].transaction_id.should == "1000000091176126"
        receipt.in_app[0].purchase_date.should == Time.utc(2013, 11, 26, 5, 58, 48)
        receipt.in_app[0].original.purchase_date.should == Time.utc(2013, 10, 24, 4, 55, 56)

        receipt.in_app[1].should be_instance_of Itunes::Receipt
        receipt.in_app[1].quantity.should == 1
        receipt.in_app[1].product_id.should == "com.tekkinnovations.fars.subscription.3.months"
        receipt.in_app[1].transaction_id.should == "1000000091221097"
        receipt.in_app[1].purchase_date.should == Time.utc(2013, 11, 26, 5, 58, 48)
        receipt.in_app[1].original.purchase_date.should == Time.utc(2013, 10, 24, 9, 40, 22)

        receipt.original.quantity.should be_nil
        receipt.original.transaction_id.should be_nil
        receipt.original.purchase_date.should == Time.utc(2013, 8, 1, 7, 00, 00)
        receipt.original.application_version.should == '1.0'

        receipt.should be_instance_of Itunes::Receipt
        receipt.quantity.should be_nil
        receipt.product_id.should be_nil
        receipt.transaction_id.should be_nil
        receipt.purchase_date.should be_nil
        receipt.bid.should be_nil
        receipt.bvrs.should be_nil
        receipt.expires_date.should be_nil
        receipt.receipt_data.should be_nil
        receipt.itunes_env.should == :production

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

    context 'when expired autorenew subscription' do
      before do
        fake_json :autorenew_subscription_expired
      end

      it 'should raise ExpiredReceiptReceived exception' do
        expect do
          Itunes::Receipt.verify! 'autorenew_subscription_expired'
        end.to raise_error Itunes::Receipt::ExpiredReceiptReceived do |e|
          e.receipt.should_not be_nil
        end
      end

    end

    context 'when offline' do
      before do
        fake_json :offline
      end

      it 'should raise ReceiptServerOffline exception' do
        expect do
          Itunes::Receipt.verify! 'offline'
        end.to raise_error Itunes::Receipt::ReceiptServerOffline
      end
    end

    describe '#latest' do
      let(:receipt) { Itunes::Receipt.verify! 'receipt-data' }
      subject { receipt.latest }

      context 'when latest_receipt_info is a Hash' do
        before do
          fake_json :autorenew_subscription
        end
        it { should be_a Itunes::Receipt }
      end

      context 'when latest_receipt_info is an Array' do
        before do
          fake_json :array_of_latest_receipt_info
        end
        it { should be_a Array }
        it 'should include only Itunes::Receipt' do
          receipt.latest.each do |element|
            element.should be_a Itunes::Receipt
          end
        end
      end
    end

    ##### MARK: Above iOS 7

    shared_examples "auto-renew subscription shared example" do
      it 'should success with sandbox access' do
        expect(receipt.sandbox?).to eq true
      end

      it { expect(receipt).to be_an_instance_of(Itunes::Receipt) }

      describe '#raw_attributes' do
        it { expect(receipt.raw_attributes).not_to be_nil }

        describe 'status in the attributes' do
          it { expect(receipt.raw_attributes[:status]).to eq 0 }
        end
      end

      describe '#bundle_id' do
        it { expect(receipt.bundle_id).to eq 'com.example.app' }
      end

      describe '#in_app' do
        subject(:in_app) { receipt.in_app }

        describe '#quantity' do
          it { in_app.each { |item| expect(item.quantity).to eq 1 } }
        end

        describe '#product_id' do
          it { in_app.each { |item| expect(item.product_id).to eq 'com.example.app.starter.1.month' } }
        end

        describe '#original.transaction_id' do
          it { expect(Set.new(in_app.map {|item| item.original.transaction_id }).size).to eq 1 }
        end

        describe '#transaction_id' do
          it 'should include #original.transaction_id' do
            expect(in_app.map {|item| item.transaction_id }).to include Set.new(in_app.map {|item| item.original.transaction_id }).first
          end
        end

        describe '#purchase_date' do
          it { in_app.each {|item| expect(item.purchase_date).to be_an_instance_of(Time) } }
        end

        describe '#expires_date' do
          it { in_app.each {|item| expect(item.expires_date).to be_an_instance_of(Time) } }
        end
      end
    end

    context 'when first auto-renew subscrsption' do
      before do
          fake_json :sandboxed
        sandbox_mode do
          fake_json :autorenew_subscription_first
        end
      end

      let(:receipt) { Itunes::Receipt.verify! 'autorenew_subscription_first', :allow_sandbox_receipt => true }

      it { expect(receipt.in_app.size).to eq(1) }
      it_behaves_like "auto-renew subscription shared example"
    end

    context 'when auto-renew subscriptions' do
      before do
          fake_json :sandboxed
        sandbox_mode do
          fake_json :autorenew_subscription_multiple
        end
      end

      let(:receipt) { Itunes::Receipt.verify! 'autorenew_subscription_multiple', :allow_sandbox_receipt => true }

      it { expect(receipt.in_app.size).to eq(6) }
      it_behaves_like "auto-renew subscription shared example"

      describe '#latest_in_app_by_product_id' do
        context 'when not match product' do
          it { expect(receipt.latest_in_app_by_product_id('com.example.app.invalid')).to be_nil }
        end

        context 'when match product' do
          it { expect(receipt.latest_in_app_by_product_id('com.example.app.starter.1.month')).to be_truthy.and be_an_instance_of(Itunes::Receipt) }
        end
      end

      describe '#find_all_by_product_id' do
        context 'when not match product' do
          it { expect(receipt.find_all_by_product_id('com.example.app.invalid').size).to eq 0 }
        end

        context 'when match product' do
          it { expect(receipt.find_all_by_product_id('com.example.app.starter.1.month').size).to eq 6 }
        end
      end

      describe '#latest_in_app' do
        subject(:latest_in_app) { receipt.latest_in_app }
        it { expect(latest_in_app).to be_instance_of(Itunes::Receipt) }

        describe '#purchase_date' do
          subject(:purchase_date) { latest_in_app.purchase_date }
          it { expect(purchase_date).to eq(purchase_date).and be > receipt.in_app.sort_by {|a| a.purchase_date }.reverse[1].purchase_date }
        end
      end

      describe '#oldest_in_app' do
        subject(:oldest_in_app) { receipt.oldest_in_app }
        it { expect(oldest_in_app).to be_instance_of(Itunes::Receipt) }

        describe '#purchase_date' do
          subject(:purchase_date) { oldest_in_app.purchase_date }
          it { expect(purchase_date).to eq(purchase_date).and be < receipt.in_app.sort_by {|a| a.purchase_date }[1].purchase_date }
        end
      end

      describe '#expired_in_app?' do
        it { expect(receipt.expired_in_app?).to be_truthy }
      end

      describe '#original_receipt_in_app' do
        subject(:original_receipt) { receipt.original_receipt_in_app }
        it { expect(original_receipt).to be_instance_of(Itunes::Receipt) }

        describe 'original_transaction_id' do
          subject(:original_transaction_id) { original_receipt.original.transaction_id }
          it { expect(original_receipt.transaction_id).to eq original_transaction_id }
          it { expect(receipt.latest_in_app.transaction_id).not_to eq original_transaction_id }
        end
      end

      describe '#latest_in_latest_by_product_id' do
        context 'when not match product' do
          it { expect(receipt.latest_in_latest_by_product_id('com.example.app.invalid')).to be_nil }
        end

        context 'when match product' do
          it { expect(receipt.latest_in_latest_by_product_id('com.example.app.starter.1.month')).to be_truthy.and be_an_instance_of(Itunes::Receipt) }
        end
      end

      describe '#find_all_in_latest_by_product_id' do
        context 'when not match product' do
          it { expect(receipt.find_all_in_latest_by_product_id('com.example.app.invalid').size).to eq 0 }
        end

        context 'when match product' do
          it { expect(receipt.find_all_in_latest_by_product_id('com.example.app.starter.1.month').size).to eq 6 }
        end
      end

      describe '#latest_in_latest' do
        subject(:latest_in_latest) { receipt.latest_in_latest }
        it { expect(latest_in_latest).to be_instance_of(Itunes::Receipt) }

        describe '#purchase_date' do
          subject(:purchase_date) { latest_in_latest.purchase_date }
          it { expect(purchase_date).to eq(purchase_date).and be > receipt.latest.sort_by(&:purchase_date).reverse[1].purchase_date }
        end
      end

      describe '#oldest_in_latest' do
        subject(:oldest_in_latest) { receipt.oldest_in_latest }
        it { expect(oldest_in_latest).to be_instance_of(Itunes::Receipt) }

        describe '#purchase_date' do
          subject(:purchase_date) { oldest_in_latest.purchase_date }
          it { expect(purchase_date).to eq(purchase_date).and be < receipt.latest.sort_by(&:purchase_date)[1].purchase_date }
        end
      end

      describe '#expired_in_latest' do
        it { expect(receipt.expired_in_latest?).to be_truthy }
      end

      describe '#original_receipt_in_latest' do
        subject(:original_receipt) { receipt.original_receipt_in_latest }
        it { expect(original_receipt).to be_instance_of(Itunes::Receipt) }

        describe 'original_transaction_id' do
          subject(:original_transaction_id) { original_receipt.original.transaction_id }
          it { expect(original_receipt.transaction_id).to eq original_transaction_id }
          it { expect(receipt.latest_in_latest.transaction_id).not_to eq original_transaction_id }
        end
      end
    end
  end
end
