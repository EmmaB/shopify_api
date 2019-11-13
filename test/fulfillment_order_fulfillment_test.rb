require 'test_helper'

class FulfillmentOrderFulfillmentTest < Test::Unit::TestCase
  def setup
    super
    fake "fulfillment_orders/519788021", method: :get,
         body: load_fixture('fulfillment_order')
  end

  context "FulfillmentOrderFulfillment" do
    context "#create" do
      should "be able to create a fulfillment order fulfillment" do
        create_fulfillment_attributes = {
          message: "The message for this FO fulfillment",
          notify_customer: true,
          tracking_info: {
            number: "XSDFHYR23475",
            url: "https://tracking.example.com/XSDFHYR23475",
            company: "TFTC - the fulfillment/tracking company"
          },
          line_items_by_fulfillment_order: [
            {
              fulfillment_order_id: 3,
              fulfillment_order_line_items: [{ id: 2, quantity: 1 }]
            }
          ]
        }
        stub_request(:post, "https://this-is-my-test-shop.myshopify.com/admin/api/2019-01/fulfillments.json").with(
          body: {
            fulfillment: create_fulfillment_attributes
          }
        ).to_return(status: 200, body: ActiveSupport::JSON.encode(create_fulfillment_attributes.merge(id: 346743624)),
                    headers: { content_type: "text/x-json" })

        fulfillment = ShopifyAPI::FulfillmentOrderFulfillment.new(create_fulfillment_attributes)

        saved = fulfillment.save

        assert_equal true, saved
        assert_equal 346743624, fulfillment.id
      end
    end

    context "#update_tracking" do
      should "be able to update tracking info for a fulfillment" do
        tracking_info = {
          number: 'JSDHFHAG',
          url: 'https://example.com/fulfillment_tracking/JSDHFHAG',
          company: 'ACME co',
        }
        fake_f = ActiveSupport::JSON.decode(load_fixture('fulfillment').gsub(/1Z2345/, 'JSDHFHAG'))['fulfillment']
        request_body = {
          fulfillment: {
            tracking_info: tracking_info,
            notify_customer: true
          }
        }
        fake "fulfillments/#{fake_f['id']}/update_tracking", method: :post,
          request_body: ActiveSupport::JSON.encode(request_body),
          body: ActiveSupport::JSON.encode(fulfillment: fake_f)

        fulfillment = ShopifyAPI::FulfillmentOrderFulfillment.new(id: fake_f['id'])
        updated = fulfillment.update_tracking(tracking_info: tracking_info, notify_customer: true)

        assert_equal true, updated
        assert_equal 'JSDHFHAG', fulfillment.tracking_number
      end
    end

    context "#cancel" do
      should "be able to cancel a fulfillment" do
        fake_f = ActiveSupport::JSON.decode(load_fixture('fulfillment'))['fulfillment']
        fake "fulfillments/#{fake_f['id']}/cancel", method: :post,
           body: ActiveSupport::JSON.encode(fulfillment: fake_f)

        fulfillment = ShopifyAPI::FulfillmentOrderFulfillment.new(id: fake_f['id'])
        cancelled = fulfillment.cancel

        assert_equal true, cancelled
        assert_equal 'pending', fulfillment.status
      end
    end
  end
end
