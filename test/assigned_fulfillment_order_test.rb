require 'test_helper'

class AssignedFulFillmentOrderTest < Test::Unit::TestCase
  context "AssignedFulfillmentOrder" do
    context "#all" do
      should "be able to list assigned fulfillment orders by assigned_status" do
        fo_fixture = load_fixture('assigned_fulfillment_orders')
        fake 'assigned_fulfillment_orders.json?assigned_status=cancellation_requested', method: :get,
             body: fo_fixture, extension: false

        assigned_fulfillment_orders = ShopifyAPI::AssignedFulfillmentOrder.all(
            params: { assigned_status: 'cancellation_requested' }
        )

        assert_equal 2, assigned_fulfillment_orders.count
        assigned_fulfillment_orders.each do |fulfillment_order|
          assert_equal 'ShopifyAPI::FulfillmentOrder', fulfillment_order.class.name
          assert_equal 'open', fulfillment_order.status
          assert_equal 'unsubmitted', fulfillment_order.request_status
        end
      end

      should "be able to list assigned fulfillment orders by location_ids" do
        fo_fixture = load_fixture('assigned_fulfillment_orders')
        assigned_location_id = 905684977
        fake "assigned_fulfillment_orders.json?location_ids%5B%5D=#{assigned_location_id}", method: :get,
             body: fo_fixture, extension: false

        assigned_fulfillment_orders = ShopifyAPI::AssignedFulfillmentOrder.all(
            params: { location_ids: [assigned_location_id] }
        )

        assert_equal 2, assigned_fulfillment_orders.count
        assigned_fulfillment_orders.each do |fulfillment_order|
          assert_equal 'ShopifyAPI::FulfillmentOrder', fulfillment_order.class.name
          assert_equal assigned_location_id, fulfillment_order.assigned_location_id
        end
      end
    end
  end
end
