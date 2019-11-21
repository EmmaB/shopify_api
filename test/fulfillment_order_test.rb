require 'test_helper'

class FulFillmentOrderTest < Test::Unit::TestCase
  def setup
    super
    fake "fulfillment_orders/519788021", method: :get,
      body: load_fixture('fulfillment_order')
  end

  context "FulfillmentOrder" do
    context "#find" do
      should "be able to find fulfillment order" do
        fulfillment_order = ShopifyAPI::FulfillmentOrder.find(519788021)
        assert_equal 'ShopifyAPI::FulfillmentOrder', fulfillment_order.class.name
        assert_equal 519788021, fulfillment_order.id
        assert_equal 450789469, fulfillment_order.order_id
      end
    end

    context "#all" do
      should "be able to list fulfillment orders for an order" do
        fake 'orders/450789469/fulfillment_orders', method: :get, body: load_fixture('fulfillment_orders')

        fulfillment_orders = ShopifyAPI::FulfillmentOrder.all(
          params: { order_id: 450789469 }
        )

        assert_equal [519788021, 519788022], fulfillment_orders.map(&:id).sort
        fulfillment_orders.each do |fulfillment_order|
          assert_equal 'ShopifyAPI::FulfillmentOrder', fulfillment_order.class.name
          assert_equal 450789469, fulfillment_order.order_id
        end
      end

      should "require order_id" do
        assert_raises ShopifyAPI::ValidationException do
          ShopifyAPI::FulfillmentOrder.all
        end
      end
    end

    context "#fulfillments" do
      should "be able to list fulfillments for a fulfillment order" do
        fulfillment_order = ShopifyAPI::FulfillmentOrder.find(519788021)
        fake "fulfillment_orders/#{fulfillment_order.id}/fulfillments", method: :get,
             body: load_fixture('fulfillments')

        fulfillments = fulfillment_order.fulfillments

        assert_equal 1, fulfillments.count
        fulfillment = fulfillments.first
        assert_equal 'ShopifyAPI::FulfillmentV2', fulfillment.class.name
        assert_equal 450789469, fulfillment.order_id
      end
    end

    context "#move" do
      should "move a fulfillment order to a new_location_id" do
        fulfillment_order = ShopifyAPI::FulfillmentOrder.find(519788021)
        new_location_id = 5

        original = fulfillment_order.clone
        original.status = 'closed'
        moved = ActiveSupport::JSON.decode(load_fixture('fulfillment_order'))
        moved['assigned_location_id'] = new_location_id

        request_body = { fulfillment_order: { new_location_id: 5 } }
        body = {
          original_fulfillment_order: original,
          moved_fulfillment_order: moved,
          remaining_fulfillment_order: nil,
        }
        fake "fulfillment_orders/519788021/move", :method => :post,
          :request_body => ActiveSupport::JSON.encode(request_body),
          :body => ActiveSupport::JSON.encode(body)

        response_fos = fulfillment_order.move(new_location_id: new_location_id)

        assert_equal 'closed', fulfillment_order.status

        assert_equal 3, response_fos.count
        original_fulfillment_order = response_fos['original_fulfillment_order']
        refute_nil original_fulfillment_order
        assert_equal 'ShopifyAPI::FulfillmentOrder', original_fulfillment_order.class.name
        assert_equal 'closed', original_fulfillment_order.status

        moved_fulfillment_order = response_fos['moved_fulfillment_order']
        refute_nil moved_fulfillment_order
        assert_equal 'ShopifyAPI::FulfillmentOrder', moved_fulfillment_order.class.name
        assert_equal 'open', moved_fulfillment_order.status
        assert_equal new_location_id, moved_fulfillment_order.assigned_location_id

        remaining_fulfillment_order = response_fos['remaining_fulfillment_order']
        assert_nil remaining_fulfillment_order
      end
    end

    context "#cancel" do
      should "cancel a fulfillment order" do
        fulfillment_order = ShopifyAPI::FulfillmentOrder.find(519788021)
        assert_equal 'open', fulfillment_order.status

        cancelled = ActiveSupport::JSON.decode(load_fixture('fulfillment_order'))
        cancelled['status'] = 'cancelled'
        body = {
          fulfillment_order: cancelled,
          replacement_fulfillment_order: fulfillment_order,
        }
        fake "fulfillment_orders/519788021/cancel", :method => :post, :body => ActiveSupport::JSON.encode(body)

        response_fos = fulfillment_order.cancel

        assert_equal 'cancelled', fulfillment_order.status
        assert_equal 2, response_fos.count
        fulfillment_order = response_fos['fulfillment_order']
        assert_equal 'cancelled', fulfillment_order.status
        replacement_fulfillment_order = response_fos['replacement_fulfillment_order']
        assert_equal 'open', replacement_fulfillment_order.status
      end
    end

    context "#close" do
      should "be able to close fulfillment order" do
        fulfillment_order = ShopifyAPI::FulfillmentOrder.find(519788021)

        closed = ActiveSupport::JSON.decode(load_fixture('fulfillment_order'))
        closed['status'] = 'closed'
        fake "fulfillment_orders/519788021/close", :method => :post, :body => ActiveSupport::JSON.encode(closed)

        assert_equal 'open', fulfillment_order.status
        assert fulfillment_order.close
        assert_equal 'closed', fulfillment_order.status
      end
    end

    context "#request_fulfillment" do
      should "make a fulfillment request for a fulfillment order including unsubmitted" do
        original_fulfillment_order = ActiveSupport::JSON.decode(load_fixture('fulfillment_order'))
        original_fulfillment_order['status'] = 'closed'
        submitted_fulfillment_order = original_fulfillment_order.clone
        submitted_fulfillment_order['id'] = 2
        submitted_fulfillment_order['status'] = 'open'
        submitted_fulfillment_order['request_status'] = 'submitted'
        unsubmitted_fulfillment_order = original_fulfillment_order.clone
        unsubmitted_fulfillment_order['id'] = 3
        unsubmitted_fulfillment_order['status'] = 'open'
        unsubmitted_fulfillment_order['request_status'] = 'unsubmitted'
        body = {
          original_fulfillment_order: original_fulfillment_order,
          submitted_fulfillment_order: submitted_fulfillment_order,
          unsubmitted_fulfillment_order: unsubmitted_fulfillment_order
        }
        request_body = {
          fulfillment_request: {
            fulfillment_order_line_items: [
              { id: 1, quantity: 1 }
            ],
            message: 'Fulfill this FO, please.'
          }
        }
        fake "fulfillment_orders/519788021/fulfillment_request", :method => :post,
          :request_body => ActiveSupport::JSON.encode(request_body),
          :body => ActiveSupport::JSON.encode(body)

        fulfillment_order = ShopifyAPI::FulfillmentOrder.find(519788021)
        params = {
          fulfillment_order_line_items: [{ id: 1, quantity: 1 }],
          message: "Fulfill this FO, please."
        }
        response_fulfillment_orders = fulfillment_order.request_fulfillment(params)

        assert_equal 'closed', fulfillment_order.status
        assert_equal 3, response_fulfillment_orders.size

        original_fo = response_fulfillment_orders['original_fulfillment_order']
        assert_equal 519788021, original_fo.id
        assert_equal 'closed', original_fo.status

        submitted_fo = response_fulfillment_orders['submitted_fulfillment_order']
        assert_equal 2, submitted_fo.id
        assert_equal 'open', submitted_fo.status
        assert_equal 'submitted', submitted_fo.request_status

        unsubmitted_fo = response_fulfillment_orders['unsubmitted_fulfillment_order']
        assert_equal 3, unsubmitted_fo.id
        assert_equal 'open', unsubmitted_fo.status
        assert_equal 'unsubmitted', unsubmitted_fo.request_status
      end

      should "make a fulfillment request for a fulfillment order excluding unsubmitted" do
        original_fulfillment_order = ActiveSupport::JSON.decode(load_fixture('fulfillment_order'))
        original_fulfillment_order['status'] = 'closed'
        submitted_fulfillment_order = original_fulfillment_order.clone
        submitted_fulfillment_order['id'] = 2
        submitted_fulfillment_order['status'] = 'open'
        submitted_fulfillment_order['request_status'] = 'submitted'
        body = {
          original_fulfillment_order: original_fulfillment_order,
          submitted_fulfillment_order: submitted_fulfillment_order,
          unsubmitted_fulfillment_order: nil,
        }
        request_body = {
          fulfillment_request: {
            fulfillment_order_line_items: [
              { id: 1, quantity: 1 }
            ],
            message: 'Fulfill this FO, please.'
          }
        }
        fake "fulfillment_orders/519788021/fulfillment_request", :method => :post,
          :request_body => ActiveSupport::JSON.encode(request_body),
          :body => ActiveSupport::JSON.encode(body)

        fulfillment_order = ShopifyAPI::FulfillmentOrder.find(519788021)
        params = {
          fulfillment_order_line_items: [{ id: 1, quantity: 1 }],
          message: "Fulfill this FO, please."
        }
        response_fulfillment_orders = fulfillment_order.request_fulfillment(params)

        assert_equal 'closed', fulfillment_order.status
        assert_equal 3, response_fulfillment_orders.size

        original_fo = response_fulfillment_orders['original_fulfillment_order']
        assert_equal 519788021, original_fo.id
        assert_equal 'closed', original_fo.status

        submitted_fo = response_fulfillment_orders['submitted_fulfillment_order']
        assert_equal 2, submitted_fo.id
        assert_equal 'open', submitted_fo.status
        assert_equal 'submitted', submitted_fo.request_status

        assert_nil response_fulfillment_orders['unsubmitted_fulfillment_order']
      end
    end

    context "#accept_fulfillment_request" do
      should "accept a fulfillment request for a fulfillment order" do
        fulfillment_order = ShopifyAPI::FulfillmentOrder.find(519788021)

        request_body = {
          'message' => "LGTM. Accept this FO fulfillment request",
          'other' => "random"
        }
        fake_response = { fulfillment_order: fulfillment_order.attributes.merge(status: 'in_progress') }
        fake "fulfillment_orders/519788021/fulfillment_request/accept", :method => :post,
          :request_body => ActiveSupport::JSON.encode(request_body),
          :body => ActiveSupport::JSON.encode(fake_response)

        params = {
          message: 'LGTM. Accept this FO fulfillment request',
          other: 'random'
        }
        accepted = fulfillment_order.accept_fulfillment_request(params)

        assert_equal true, accepted
        assert_equal 'in_progress', fulfillment_order.status
      end
    end

    context "#reject_fulfillment_request" do
      should "reject a fulfillment request for a fulfillment order" do
        fulfillment_order = ShopifyAPI::FulfillmentOrder.find(519788021)

        request_body = {
          'message' => "LBTM. Reject this FO fulfillment request",
          'other' => "text"
        }
        fake_response = { fulfillment_order: fulfillment_order.attributes.merge(status: 'closed') }
        fake "fulfillment_orders/519788021/fulfillment_request/reject", :method => :post,
          :request_body => ActiveSupport::JSON.encode(request_body),
          :body => ActiveSupport::JSON.encode(fake_response)

        params = {
          message: 'LBTM. Reject this FO fulfillment request',
          other: 'text'
        }
        rejected = fulfillment_order.reject_fulfillment_request(params)

        assert_equal true, rejected
        assert_equal 'closed', fulfillment_order.status
      end
    end

    context "#request_cancellation" do
      should "make a cancellation request for a fulfillment order" do
        fulfillment_order = ShopifyAPI::FulfillmentOrder.find(519788021)

        cancelling = ActiveSupport::JSON.decode(load_fixture('fulfillment_order'))
        cancelling['status'] = 'in_progress'
        cancelling['request_status'] = 'cancellation_accepted'
        fake "fulfillment_orders/519788021/cancellation_request", :method => :post,
          :body => ActiveSupport::JSON.encode(cancelling)

        cancelled = fulfillment_order.request_cancellation(message: "Cancelling this please.")

        assert_equal true, cancelled
        assert_equal 'in_progress', fulfillment_order.status
        assert_equal 'cancellation_accepted', fulfillment_order.request_status
      end
    end

    context "#accept_cancellation_request" do
      should "accept a cancellation request for a fulfillment order" do
        fulfillment_order = ShopifyAPI::FulfillmentOrder.find(519788021)

        request_body = {
          'message' => "Already in-progress. Reject this FO cancellation request",
          'other' => "blah"
        }
        fake_response = { fulfillment_order: fulfillment_order.attributes.merge(status: 'closed') }
        fake "fulfillment_orders/519788021/cancellation_request/accept", :method => :post,
          :request_body => ActiveSupport::JSON.encode(request_body),
          :body => ActiveSupport::JSON.encode(fake_response)

        params = {
          message: 'Already in-progress. Reject this FO cancellation request',
          other: 'blah'
        }
        accepted = fulfillment_order.accept_cancellation_request(params)

        assert_equal true, accepted
        assert_equal 'closed', fulfillment_order.status
      end
    end

    context "#reject_cancellation_request" do
      should "reject a cancellation request for a fulfillment order" do
        fulfillment_order = ShopifyAPI::FulfillmentOrder.find(519788021)

        request_body = {
          'message' => "Already in-progress. Reject this FO cancellation request",
          'other' => "blah"
        }
        fake_response = { fulfillment_order: fulfillment_order.attributes.merge(status: 'in_progress') }
        fake "fulfillment_orders/519788021/cancellation_request/reject", :method => :post,
          :request_body => request_body,
          :body => ActiveSupport::JSON.encode(fake_response)

        params = {
          message: 'Already in-progress. Reject this FO cancellation request',
          other: 'blah'
        }
        rejected = fulfillment_order.reject_cancellation_request(params)

        assert_equal true, rejected
        assert_equal 'in_progress', fulfillment_order.status
      end
    end

  end
end
