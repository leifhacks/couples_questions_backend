# frozen_string_literal: true

module Api
  module V1
    #---------------------------------------------------------------------------
    # A controller class for friendship related requests
    #---------------------------------------------------------------------------
    class IosMultiVerificationController < GenericController

      def initialize
        super(Validate::IosVerification, Base64Decoder.new)
      end

      def verify
        receipt_data_list = params[:receipt_data]
        return render json: { status: -2 } if receipt_data_list.nil?

        verify_list(ENV['IOS_VERIFICATION_KEY'], receipt_data_list)
      end

      def verify_list(key, receipt_data_list)
        return render json: { status: 0, result: [] } if receipt_data_list.empty?

        result = []

        receipt_data_list.each do |receipt_data|
          decoded = try_verify_storekit2(receipt_data)
          if decoded.nil?
            decoded_list = verify_storekit_v1(key, receipt_data)
            result += decoded_list unless decoded_list.nil?
          else
            result.push(decoded)
          end
        end

        if result.empty?
          render json: { status: -1 }
        else
          render json: { status: 0, result: result }
        end
      end

      def verify_storekit_v1(key, receipt_data)
        receipt_body = {
          'receipt-data': receipt_data,
          'exclude-old-transactions': true,
          'password': key
        }
        url_keys = %i[ios_production_verification ios_sandbox_verification]

        verify_by_urls(receipt_body, url_keys)
      end

      def verify_by_urls(receipt_body, url_keys)
        url_keys.each do |url_key|
          response = post_request(receipt_body, url_key)
          return if response.code != '200'

          json_response = JSON.parse(response.body)
          status = json_response['status']

          next if status == 21_007
          return if status.nil? || status != 0

          return build_response(json_response)
        end

        render json: { status: -1 }
      end

      def post_request(receipt_body, url_key)
        uri = URI(LINKS[url_key])
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true

        request = Net::HTTP::Post.new(uri.path)
        request['Accept'] = 'application/json'
        request['Content-Type'] = 'application/json'

        request.body = JSON.generate(receipt_body).encode('UTF-8')
        https.request(request)
      end

      def build_response(json_response)
        receipt = json_response['latest_receipt_info']
        receipt_id = json_response['latest_receipt']
        return if receipt_id.nil? || receipt.nil?

        result = []

        receipt.each do |json|
          result.push({
                        is_expired: is_expired(json['expires_date_ms']),
                        product_id: json['product_id'],
                        transaction_id: json['transaction_id'],
                        purchase_date_ms: json['purchase_date_ms']
                      })
        end

        result
      end

      def try_verify_storekit2(receipt_data)
        jwt = JWT.decode(receipt_data, nil, false)
        expires_ms = jwt[0]['expiresDate']

        {
          is_expired: is_expired(expires_ms),
          product_id: jwt[0]['productId'],
          transaction_id: jwt[0]['transactionId'],
          purchase_date_ms: jwt[0]['purchaseDate'].to_s,
          verification_data: receipt_data
        }

      rescue => e
        nil
      end

      def is_expired(expires_ms)
        !expires_ms.nil? && Time.at(expires_ms.to_i / 1000).utc.to_datetime.before?(DateTime.now)
      end
    end
  end
end
