module ShopifyAPI
  class FulfillmentOrder < Base
    def self.all(options = {})
      order_id = options.dig(:params, :order_id)
      raise ShopifyAPI::ValidationException, "'order_id' is required" if order_id.nil? || order_id == ''

      order = ::ShopifyAPI::Order.new(id: order_id)
      order.fulfillment_orders
    end

    def fulfillments(options = {})
      fo_fulfillments = get(:fulfillments, options)
      fo_fulfillments.map { |fof| FulfillmentV2.new(fof.as_json) }
    end
  end
end
