require 'spec_helper'

module Spree
  describe Spree::Api::LineItemsController, type: :controller do
    render_views

    #test that when a line item is updated, an order's fees are updated too
    context "as an admin user" do
      let(:current_api_user) { build_stubbed(:user) }

      before do
        allow(controller).to receive(:spree_current_user) { current_api_user }

        allow(current_api_user)
          .to receive(:has_spree_role?).with('admin').and_return(true)
      end

      let(:order) do
        create(:order, state: 'complete', completed_at: Time.zone.now)
      end
      let(:line_item) do
        create(:line_item, order: order, final_weight_volume: 500)
      end
      let(:line_item_params) do
        {
          order_id: order.number,
          id: line_item.id,
          line_item: { id: line_item.id, final_weight_volume: 520 },
          format: :json
        }
      end

      context "as a line item is updated" do
        before { allow(controller).to receive(:order) { order } }

        it "update distribution charge on the order" do
          expect(order).to receive(:update_distribution_charge!)
          spree_post :update, line_item_params
        end
      end
    end
  end
end
