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

    # expires_date, receipt_data, and latest (receipt) will only appear for autorenew subscription products
    attr_reader :quantity, :product_id, :transaction_id, 
                :is_trial_period,
                :purchase_date, :purchase_date_ms, :purchase_date_pst,
                :original_purchase_date, :original_purchase_date_ms, :original_purchase_date_pst, 
                :original_transaction_id
                
    attr_reader :app_item_id, :version_external_identifier, :bid, :bvrs, :original, 
                :expires_date, :receipt_data, :latest, :itunes_env
                
    attr_reader :adam_id, :application_version, :bundle_id, :download_id, :in_app,
                :receipt_type, :request_date, :request_date_ms, :request_date_pst

    # These attributes are not currently used
    # attr_reader :purchase_date_ms, :purchase_date_pst,
    #             :original_purchase_date_ms, :original_purchase_date_pst, 
    #             :original, 
    #             :request_date_ms, :request_date_pst

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
      @app_item_id = receipt_attributes[:app_item_id]
      @version_external_identifier = receipt_attributes[:version_external_identifier]
      @bid = receipt_attributes[:bid]
      @bvrs = receipt_attributes[:bvrs]
      @request_date = if receipt_attributes[:request_date]
        Time.parse receipt_attributes[:request_date].sub('Etc/', '')
      end
      
      if receipt_attributes[:original_transaction_id] || receipt_attributes[:original_purchase_date]
        @original = self.class.new(:receipt => {
          :transaction_id => receipt_attributes[:original_transaction_id],
          :purchase_date => receipt_attributes[:original_purchase_date],
          :application_version => receipt_attributes[:original_application_version]
        })
      end

      @adam_id = receipt_attributes[:adam_id]
      @application_version = receipt_attributes[:application_version]
      @bundle_id = receipt_attributes[:bundle_id]
      @download_id = receipt_attributes[:download_id]

      if receipt_attributes[:is_trial_period]
        @is_trial_period = receipt_attributes[:is_trial_period]
      end

      if receipt_attributes[:in_app]
        @in_app = receipt_attributes[:in_app].map { |ia| self.class.new(:receipt => ia) }
      end

      # autorenew subscription handling
      # attributes[:latest_receipt_info] and attributes[:latest_receipt] will be nil if you already have the receipt for the most recent renewal.
      if attributes[:latest_receipt_info]
        full_receipt_data = attributes[:latest_receipt] # should also be in the top-level hash if attributes[:latest_receipt_info] is there, but this won't break if it isn't
        @latest = self.class.new(:receipt => attributes[:latest_receipt_info], :latest_receipt => full_receipt_data, :receipt_type => :latest)
      end
      @expires_date = Time.at(receipt_attributes[:expires_date].to_i / 1000) if receipt_attributes[:expires_date]
      @receipt_data = attributes[:latest_receipt] if attributes[:receipt_type] == :latest # it feels wrong to include the receipt_data for the latest receipt on anything other than the latest receipt

      @itunes_env = attributes[:itunes_env] || Itunes.itunes_env
    end

    def to_h
      {
        :quantity => @quantity,
        :product_id => @product_id,
        :transaction_id => @transaction_id,
        :purchase_date => (@purchase_date rescue nil),
        :original_transaction_id => (@original.transaction_id rescue nil),
        :original_purchase_date => (@original.purchase_date rescue nil),
        :is_trial_period => @is_trial_period,
        # :app_item_id => @app_item_id,
        # :version_external_identifier => @version_external_identifier,
        # :bid => @bid,
        # :bvrs => @bvrs,
        # :expires_at => (@expires_at.httpdate rescue nil)
      }.tap do |receipt_h| 
        receipt_h[:application_version] = @application_version if @application_version.presence
        receipt_h[:bundle_id] = @bundle_id if @bundle_id.presence
      end
    end

    def to_json
      self.to_h.to_json
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
