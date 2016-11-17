module OpenFoodNetwork
  describe StandingOrderForm do
    describe "creating a new standing order" do
      let!(:shop) { create(:distributor_enterprise) }
      let!(:customer) { create(:customer, enterprise: shop) }
      let!(:product1) { create(:product, supplier: shop) }
      let!(:product2) { create(:product, supplier: shop) }
      let!(:product3) { create(:product, supplier: shop) }
      let!(:variant1) { create(:variant, product: product1, unit_value: '100', price: 12.00, option_values: []) }
      let!(:variant2) { create(:variant, product: product2, unit_value: '1000', price: 6.00, option_values: []) }
      let!(:variant3) { create(:variant, product: product2, unit_value: '1000', price: 2.50, option_values: []) }
      let!(:enterprise_fee) { create(:enterprise_fee, amount: 1.75) }
      let!(:order_cycle1) { create(:simple_order_cycle, coordinator: shop, orders_open_at: 9.days.ago, orders_close_at: 2.day.ago) }
      let!(:order_cycle2) { create(:simple_order_cycle, coordinator: shop, orders_open_at: 2.day.ago, orders_close_at: 5.days.from_now) }
      let!(:order_cycle3) { create(:simple_order_cycle, coordinator: shop, orders_open_at: 5.days.from_now, orders_close_at: 12.days.from_now) }
      let!(:order_cycle4) { create(:simple_order_cycle, coordinator: shop, orders_open_at: 12.days.from_now, orders_close_at: 19.days.from_now) }
      let!(:outgoing_exchange1) { order_cycle1.exchanges.create(sender: shop, receiver: shop, variants: [variant1, variant2, variant3], enterprise_fees: [enterprise_fee]) }
      let!(:outgoing_exchange2) { order_cycle2.exchanges.create(sender: shop, receiver: shop, variants: [variant1, variant2, variant3], enterprise_fees: [enterprise_fee]) }
      let!(:outgoing_exchange3) { order_cycle3.exchanges.create(sender: shop, receiver: shop, variants: [variant1, variant3], enterprise_fees: []) }
      let!(:outgoing_exchange4) { order_cycle4.exchanges.create(sender: shop, receiver: shop, variants: [variant1, variant2, variant3], enterprise_fees: [enterprise_fee]) }
      let!(:schedule) { create(:schedule, order_cycles: [order_cycle1, order_cycle2, order_cycle3, order_cycle4]) }
      let!(:payment_method) { create(:payment_method, distributors: [shop]) }
      let!(:shipping_method) { create(:shipping_method, distributors: [shop]) }
      let!(:address) { create(:address) }
      let(:standing_order) { StandingOrder.new }

      let!(:params) { {
        shop_id: shop.id,
        customer_id: customer.id,
        schedule_id: schedule.id,
        bill_address_attributes: address.clone.attributes,
        ship_address_attributes: address.clone.attributes,
        payment_method_id: payment_method.id,
        shipping_method_id: shipping_method.id,
        begins_at: 4.days.ago,
        ends_at: 14.days.from_now,
        standing_line_items_attributes: [
          {variant_id: variant1.id, quantity: 1},
          {variant_id: variant2.id, quantity: 2},
          {variant_id: variant3.id, quantity: 3}
        ]
      } }

      let(:form) { StandingOrderForm.new(standing_order, params) }

      it "creates orders for each order cycle in the schedule" do
        form.save

        expect(standing_order.orders.count).to be 2

        # This order cycle has already closed, so no order is initialized
        order1 = standing_order.orders.find_by_order_cycle_id(order_cycle1.id)
        expect(order1).to be nil

        # Currently open order cycle, closing after begins_at and before ends_at
        order2 = standing_order.orders.find_by_order_cycle_id(order_cycle2.id)
        expect(order2).to be_a Spree::Order
        expect(order2.line_items.count).to be 3
        expect(order2.shipments.count).to be 1
        expect(order2.shipments.first.shipping_method).to eq shipping_method
        expect(order2.payments.count).to be 1
        expect(order2.payments.first.payment_method).to eq payment_method
        expect(order2.payments.first.state).to eq 'checkout'
        expect(order2.total).to eq 42
        expect(order2.completed?).to be false

        # Future order cycle, closing after begins_at and before ends_at
        # Add line items for variants that aren't yet available from the order cycle
        order3 = standing_order.orders.find_by_order_cycle_id(order_cycle3.id)
        expect(order3).to be_a Spree::Order
        expect(order3.line_items.count).to be 3
        expect(order3.shipments.count).to be 1
        expect(order3.shipments.first.shipping_method).to eq shipping_method
        expect(order3.payments.count).to be 1
        expect(order3.payments.first.payment_method).to eq payment_method
        expect(order3.payments.first.state).to eq 'checkout'
        expect(order3.total).to eq 31.50
        expect(order3.completed?).to be false

        # Future order cycle closing after ends_at
        order4 = standing_order.orders.find_by_order_cycle_id(order_cycle4.id)
        expect(order4).to be nil
      end
    end

    describe "changing the shipping method" do
      let(:standing_order) { create(:standing_order_with_items) }
      let(:shipping_method) { standing_order.shipping_method }
      let(:new_shipping_method) { create(:shipping_method, distributors: [standing_order.shop]) }
      let(:order) { standing_order.orders.first }
      let(:params) { { shipping_method_id: new_shipping_method.id } }
      let(:form) { StandingOrderForm.new(standing_order, params) }

      context "when the shipping method on an order is the same as the standing order" do
        before { form.send(:initialise_orders!) }

        it "updates the shipping_method on the order and on shipments" do
          expect(order.shipments.first.shipping_method).to eq shipping_method
          form.save
          expect(order.shipping_method).to eq new_shipping_method
          expect(order.shipments.first.shipping_method).to eq new_shipping_method
        end
      end

      context "when the shipping method on a shipment is not the same as the standing order" do
        let(:changed_shipping_method) { create(:shipping_method) }

        before do
          form.send(:initialise_orders!)
          # Updating the shipping method on a shipment updates the shipping method on the order,
          # and vice-versa via logic in Spree's shipments controller. So updating both here mimics that
          # behaviour.
          order.shipments.first.update_attributes(shipping_method_id: changed_shipping_method.id)
          order.update_attributes(shipping_method_id: changed_shipping_method.id)
          form.save
        end

        it "does not update the shipping_method on the standing order or on the pre-altered shipment" do
          expect(order.reload.shipping_method).to eq changed_shipping_method
          expect(order.reload.shipments.first.shipping_method).to eq changed_shipping_method
        end
      end
    end

    describe "changing the payment method" do
      let(:standing_order) { create(:standing_order_with_items) }
      let(:order) { standing_order.orders.first }
      let(:payment_method) { standing_order.payment_method }
      let(:new_payment_method) { create(:payment_method, distributors: [standing_order.shop]) }
      let(:params) { { payment_method_id: new_payment_method.id } }
      let(:form) { StandingOrderForm.new(standing_order, params) }

      context "when the payment method on an order is the same as the standing order" do
        before { form.send(:initialise_orders!) }

        it "voids existing payments and creates a new payment with the relevant payment method" do
          expect(order.payments.reload.first.payment_method).to eq payment_method
          form.save
          payments = order.reload.payments
          expect(payments.count).to be 2
          expect(payments.with_state('void').count).to be 1
          expect(payments.with_state('checkout').count).to be 1
          expect(payments.with_state('void').first.payment_method).to eq payment_method
          expect(payments.with_state('checkout').first.payment_method).to eq new_payment_method
        end
      end

      context "when the payment method on a payment is not the same as the standing order" do
        let(:changed_payment_method) { create(:payment_method) }

        before do
          form.send(:initialise_orders!)
          order.payments.first.update_attribute(:payment_method_id, changed_payment_method.id)
          form.save
        end

        it "keeps pre-altered payments" do
          payments = order.reload.payments
          expect(payments.count).to be 1
          expect(payments.first.payment_method).to eq changed_payment_method
        end
      end
    end

    describe "changing begins_at" do
      let(:standing_order) { create(:standing_order_with_items, begins_at: Time.zone.now) }
      let(:params) { { begins_at: 1.year.from_now, ends_at: 2.years.from_now } }
      let(:form) { StandingOrderForm.new(standing_order, params) }

      before { form.send(:initialise_orders!) }

      it "removes orders outside the newly specified date range" do
        expect(standing_order.reload.orders.count).to be 1
        form.save
        expect(standing_order.reload.orders.count).to be 0
        form.params = { begins_at: 1.month.ago }
        form.save
        expect(standing_order.reload.orders.count).to be 1
      end
    end

    describe "changing the quantity of a line item" do
      let(:standing_order) { create(:standing_order_with_items) }
      let(:sli) { standing_order.standing_line_items.first }
      let(:params) { { standing_line_items_attributes: [ { id: sli.id, quantity: 4} ] } }
      let(:form) { StandingOrderForm.new(standing_order, params) }

      before { form.save }

      it "updates the quantity on all orders" do
        line_items = Spree::LineItem.where(order_id: standing_order.orders, variant_id: sli.variant_id)
        expect(line_items.map(&:quantity)).to eq [4]
      end
    end
  end
end