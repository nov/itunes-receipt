$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '../..', 'lib'))
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

    attr_reader :quantity, :product_id, :transaction_id, :purchase_date, :app_item_id, :version_external_identifier, :bid, :bvrs, :original

    def initialize(attributes = {})
      if attributes[:quantity]
        @quantity = attributes[:quantity].to_i
      end
      @product_id = attributes[:product_id]
      @transaction_id = attributes[:transaction_id]
      @purchase_date = if attributes[:purchase_date]
        Time.parse attributes[:purchase_date].sub('Etc/', '')
      end
      @app_item_id = attributes[:app_item_id]
      @version_external_identifier = attributes[:version_external_identifier]
      @bid = attributes[:bid]
      @bvrs = attributes[:bvrs]
      if attributes[:original_transaction_id] || attributes[:original_purchase_date]
        @original = self.class.new(
          :transaction_id => attributes[:original_transaction_id],
          :purchase_date => attributes[:original_purchase_date]
        )
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
        new response[:receipt]
      else
        raise VerificationFailed.new response
      end
    end
  end
end
