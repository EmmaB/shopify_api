require 'test_helper'

class FulfillmentV2Test < Test::Unit::TestCase
  context "FulfillmentV2" do
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
        request_body = { fulfillment: create_fulfillment_attributes }
        response_body = { fulfillment: create_fulfillment_attributes.merge(id: 346743624) }
        fake "fulfillments", :method => :post,
          :request_body => ActiveSupport::JSON.encode(request_body),
          :body => ActiveSupport::JSON.encode(response_body)

        fulfillment = ShopifyAPI::FulfillmentV2.new(create_fulfillment_attributes)
        assert fulfillment.save
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
        fake_fulfillment = ActiveSupport::JSON.decode(load_fixture('fulfillment'))['fulfillment']
        fake_fulfillment['tracking_number'] = tracking_info[:number]
        fake_fulfillment['tracking_numbers'] = [tracking_info[:number]]
        fake_fulfillment['tracking_url'] = tracking_info[:url]
        fake_fulfillment['tracking_urls'] = [tracking_info[:url]]
        fake_fulfillment['tracking_company'] = tracking_info[:company]

        request_body = {
          fulfillment: {
            tracking_info: tracking_info,
            notify_customer: true
          }
        }
        fake "fulfillments/#{fake_fulfillment['id']}/update_tracking", method: :post,
          request_body: ActiveSupport::JSON.encode(request_body),
          body: ActiveSupport::JSON.encode(fulfillment: fake_fulfillment)

        fulfillment = ShopifyAPI::FulfillmentV2.new(id: fake_fulfillment['id'])
        assert fulfillment.update_tracking(tracking_info: tracking_info, notify_customer: true)

        assert_equal tracking_info[:number], fulfillment.tracking_number
        assert_equal [tracking_info[:number]], fulfillment.tracking_numbers
        assert_equal tracking_info[:url], fulfillment.tracking_url
        assert_equal [tracking_info[:url]], fulfillment.tracking_urls
        assert_equal tracking_info[:company], fulfillment.tracking_company
      end
    end

    context "#cancel" do
      should "be able to cancel a fulfillment" do
        fake_fulfillment = ActiveSupport::JSON.decode(load_fixture('fulfillment'))['fulfillment']
        fake_fulfillment['status'] = 'cancelled'
        fake "fulfillments/#{fake_fulfillment['id']}/cancel", method: :post,
           body: ActiveSupport::JSON.encode(fulfillment: fake_fulfillment)

        fulfillment = ShopifyAPI::FulfillmentV2.new(id: fake_fulfillment['id'])
        assert fulfillment.cancel
        assert_equal 'cancelled', fulfillment.status
      end
    end
  end
end
