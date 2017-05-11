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

    class SandboxReceiptReceived < VerificationFailed; end;

    class ReceiptServerOffline < VerificationFailed; end;

    class ExpiredReceiptReceived < VerificationFailed
      attr_reader :receipt
      def initialize(attributes = {})
        @receipt = attributes[:receipt]
        super attributes
      end
    end

    attr_reader(
      :adam_id,
      :app_item_id,
      :application_version,
      :bid,
      :bundle_id,
      :bvrs,
      :cancellation_date,
      :cancellation_date_ms,
      :cancellation_date_pst,
      :download_id,
      :expires_date,
      :expires_date_ms,
      :expires_date_pst,
      :in_app,
      :is_trial_period,
      :itunes_env,
      :latest,
      :original,
      :product_id,
      :purchase_date,
      :purchase_date_ms,
      :purchase_date_pst,
      :quantity,
      :receipt_data,
      :request_date,
      :request_date_ms,
      :request_date_pst,
      :transaction_id,
      :version_external_identifier,
      :web_order_line_item_id
    )

    def initialize(attributes = {})
      receipt_attributes = attributes.with_indifferent_access[:receipt]
      @adam_id = receipt_attributes[:adam_id]
      @app_item_id = receipt_attributes[:app_item_id]
      @application_version = receipt_attributes[:application_version]
      @bid = receipt_attributes[:bid]
      @bundle_id = receipt_attributes[:bundle_id]
      @bvrs = receipt_attributes[:bvrs]
      @cancellation_date = if receipt_attributes[:cancellation_date]
        Time.parse receipt_attributes[:cancellation_date].sub('Etc/GMT', 'GMT')
      end
      @cancellation_date_ms = if receipt_attributes[:cancellation_date_ms]
        receipt_attributes[:cancellation_date_ms].to_i
      end
      @cancellation_date_pst = if receipt_attributes[:cancellation_date_pst]
        Time.parse receipt_attributes[:cancellation_date_pst].sub('America/Los_Angeles', 'PST')
      end
      @download_id = receipt_attributes[:download_id]
      @expires_date = if receipt_attributes[:expires_date]
        Time.parse receipt_attributes[:expires_date].sub('Etc/GMT', 'GMT')
      end
      @expires_date_ms = if receipt_attributes[:expires_date_ms]
        receipt_attributes[:expires_date_ms].to_i
      end
      @expires_date_pst = if receipt_attributes[:expires_date_pst]
        Time.parse receipt_attributes[:expires_date_pst].sub('America/Los_Angeles', 'PST')
      end
      @in_app = if receipt_attributes[:in_app]
        receipt_attributes[:in_app].map { |ia| self.class.new(:receipt => ia) }
      end
      @is_trial_period = if receipt_attributes[:is_trial_period]
        receipt_attributes[:is_trial_period] == "true"
      end
      @itunes_env = attributes[:itunes_env] || Itunes.itunes_env
      @latest = case attributes[:latest_receipt_info]
      when Hash
        self.class.new(
          :receipt        => attributes[:latest_receipt_info],
          :latest_receipt => attributes[:latest_receipt],
          :receipt_type   => :latest
        )
      when Array
        attributes[:latest_receipt_info].collect do |latest_receipt_info|
          self.class.new(
            :receipt        => latest_receipt_info,
            :latest_receipt => attributes[:latest_receipt],
            :receipt_type   => :latest
          )
        end
      end
      @original = if receipt_attributes[:original_transaction_id] || receipt_attributes[:original_purchase_date]
        self.class.new(:receipt => {
          :transaction_id      => receipt_attributes[:original_transaction_id],
          :purchase_date       => receipt_attributes[:original_purchase_date],
          :purchase_date_ms    => receipt_attributes[:original_purchase_date_ms],
          :purchase_date_pst   => receipt_attributes[:original_purchase_date_pst],
          :application_version => receipt_attributes[:original_application_version]
        })
      end
      @product_id = receipt_attributes[:product_id]
      @purchase_date = if receipt_attributes[:purchase_date]
        Time.parse receipt_attributes[:purchase_date].sub('Etc/GMT', 'GMT')
      end
      @purchase_date_ms = if receipt_attributes[:purchase_date_ms]
        receipt_attributes[:purchase_date_ms].to_i
      end
      @purchase_date_pst = if receipt_attributes[:purchase_date_pst]
        Time.parse receipt_attributes[:purchase_date_pst].sub('America/Los_Angeles', 'PST')
      end
      @quantity = if receipt_attributes[:quantity]
        receipt_attributes[:quantity].to_i
      end
      @receipt_data = if attributes[:receipt_type] == :latest
        attributes[:latest_receipt]
      end
      @request_date = if receipt_attributes[:request_date]
        Time.parse receipt_attributes[:request_date].sub('Etc/', '')
      end
      @request_date_ms = if receipt_attributes[:request_date_ms]
        receipt_attributes[:request_date_ms].to_i
      end
      @request_date_pst = if receipt_attributes[:request_date_pst]
        Time.parse receipt_attributes[:request_date_pst].sub('America/Los_Angeles', 'PST')
      end
      @transaction_id = receipt_attributes[:transaction_id]
      @version_external_identifier = receipt_attributes[:version_external_identifier]
      @web_order_line_item_id = receipt_attributes[:web_order_line_item_id]
    end

    def application_receipt?
      !@bundle_id.nil?
    end

    def sandbox?
      itunes_env == :sandbox
    end

    def self.verify!(receipt_data, allow_sandbox_receipt = false)
      request_data = {:'receipt-data' => receipt_data}
      request_data.merge!(:password => Itunes.shared_secret) if Itunes.shared_secret
      response = post_to_endpoint(request_data)
      begin
        successful_response(response)
      rescue SandboxReceiptReceived => e
        # Retry with sandbox, as per:
        # http://developer.apple.com/library/ios/#technotes/tn2259/_index.html
        #   FAQ#16
        if allow_sandbox_receipt
          sandbox_response = post_to_endpoint(request_data, Itunes::ENDPOINT[:sandbox])
          successful_response(
            sandbox_response.merge(:itunes_env => :sandbox)
          )
        else
          raise e
        end
      end
    end

    private

    def self.post_to_endpoint(request_data, endpoint = Itunes.endpoint)
      response = RestClient.post(
        endpoint,
        request_data.to_json
      )
      response = JSON.parse(response).with_indifferent_access
    end

    def self.successful_response(response)
      case response[:status]
      when 0
        new response
      when 21005
        raise ReceiptServerOffline.new(response)
      when 21006
        raise ExpiredReceiptReceived.new(response)
      when 21007
        raise SandboxReceiptReceived.new(response)
      else
        raise VerificationFailed.new(response)
      end
    end

  end
end
