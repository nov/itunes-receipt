require 'itunes'

module Itunes
  class Receipt
    class VerificationFailed < StandardError
      attr_reader :status
      def initialize(attributes = {})
        @status = attributes[:status]
        super attributes[:exception]
      end
    end

    # expires_date and latest (receipt) will only appear for autorenew subscription products
    attr_reader :quantity, :product_id, :transaction_id, :purchase_date, :expires_date, :app_item_id, :version_external_identifier, :bid, :bvrs, :original, :latest

    def initialize(attributes = {})
      receipt_attributes = attributes.with_indifferent_access[:receipt]
      if receipt_attributes[:quantity]
        @quantity = receipt_attributes[:quantity].to_i
      end
      @product_id = receipt_attributes[:product_id]
      @transaction_id = receipt_attributes[:transaction_id]
      @purchase_date = if receipt_attributes[:purchase_date]
        Time.parse receipt_attributes[:purchase_date].sub('Etc/', '')
      end
      @expires_date = Time.at(receipt_attributes[:expires_date].to_i / 1000) if receipt_attributes[:expires_date]
      @app_item_id = receipt_attributes[:app_item_id]
      @version_external_identifier = receipt_attributes[:version_external_identifier]
      @bid = receipt_attributes[:bid]
      @bvrs = receipt_attributes[:bvrs]
      if receipt_attributes[:original_transaction_id] || receipt_attributes[:original_purchase_date]
        @original = self.class.new(:receipt => {
          :transaction_id => receipt_attributes[:original_transaction_id],
          :purchase_date => receipt_attributes[:original_purchase_date]
        })
      end
      if attributes[:latest_receipt_info]
        @latest = self.class.new(:receipt => attributes[:latest_receipt_info])
      end
    end

    def self.verify!(receipt_data)
      response = RestClient.post(
        Itunes.endpoint,
        {:'receipt-data' => receipt_data}.to_json
      )
      response = JSON.parse(response).with_indifferent_access
      case response[:status]
      when 0
        new response
      else
        raise VerificationFailed.new(response)
      end
    end
  end
end
