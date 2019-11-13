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

    def move(new_location_id:)
      body = { fulfillment_order: { new_location_id: new_location_id } }.to_json
      keyed_fos = load_keyed_fulfillment_orders_from_response(post(:move, {}, body))
      if keyed_fos&.fetch('original_fulfillment_order', nil)&.attributes
        load(keyed_fos['original_fulfillment_order'].attributes, false, true)
      end
      keyed_fos
    end

    def cancel
      keyed_fos = load_keyed_fulfillment_orders_from_response(post(:cancel, {}, only_id))
      if keyed_fos&.fetch('fulfillment_order', nil)&.attributes
        load(keyed_fos['fulfillment_order'].attributes, false, true)
      end
      keyed_fos
    end

    def close
      load_attributes_from_response(post(:close, {}, only_id))
    end

    private

    def load_keyed_fulfillment_orders_from_response(response)
      return load_attributes_from_response(response) if response.code != '200'

      keyed_fulfillment_orders = ActiveSupport::JSON.decode(response.body)
      keyed_fulfillment_orders.map do |key, fo_attributes|
        if fo_attributes.nil?
          [key, nil]
        else
          [key, FulfillmentOrder.new(fo_attributes)]
        end
      end.to_h
    end
  end
end
