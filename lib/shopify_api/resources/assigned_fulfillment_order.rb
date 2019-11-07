module ShopifyAPI
  class AssignedFulfillmentOrder < Base
    CANCELLATION_REQUESTED = 'cancellation_requested'
    FULFILLMENT_REQUESTED = 'fulfillment_requested'
    FULFILLMENT_ACCEPTED = 'fulfillment_accepted'

    def self.all(options = {})
      assigned_fulfillment_orders = super(options)
      assigned_fulfillment_orders.map { |afo| FulfillmentOrder.new(afo.as_json) }
    end
  end
end
