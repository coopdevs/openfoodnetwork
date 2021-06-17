# frozen_string_literal: true

require 'spec_helper'

module Api
  describe V0::StatesController do
    render_views

    let!(:state) { create(:state, name: "Victoria") }
    let(:attributes) { [:id, :name, :abbr, :country_id] }
    let(:current_user) { create(:user) }

    before do
      allow(controller).to receive(:spree_current_user) { current_user }
    end

    it "gets all states" do
      api_get :index
      expect(json_response.first.symbolize_keys.keys).to include(*attributes)
      expect(json_response.map { |state| state[:name] }).to include(state.name)
    end

    context "pagination" do
      before do
        expect(Spree::State).to receive(:all).and_return(@scope = double)
        allow(@scope).to receive_message_chain(:ransack, :result, :includes,
                                               :order).and_return(@scope)
      end

      it "does not paginate states results when asked not to do so" do
        expect(@scope).not_to receive(:page)
        expect(@scope).not_to receive(:per)
        api_get :index
      end

      it "paginates when page parameter is passed through" do
        expect(@scope).to receive(:page).with("1").and_return(@scope)
        expect(@scope).to receive(:per).with(nil)
        api_get :index, page: 1
      end

      it "paginates when per_page parameter is passed through" do
        expect(@scope).to receive(:page).with(nil).and_return(@scope)
        expect(@scope).to receive(:per).with("25")
        api_get :index, per_page: 25
      end
    end

    context "with two states" do
      before { create(:state, name: "New South Wales") }

      it "gets all states for a country" do
        country = create(:country, states_required: true)
        state.country = country
        state.save

        api_get :index, country_id: country.id
        expect(json_response.first.symbolize_keys.keys).to include(*attributes)
        expect(json_response.count).to eq 1
      end

      it "can view all states" do
        api_get :index
        expect(json_response.first.symbolize_keys.keys).to include(*attributes)
      end

      it 'can query the results through a paramter' do
        api_get :index, q: { name_cont: 'Vic' }
        expect(json_response.first['name']).to eq("Victoria")
      end
    end

    it "can view a state" do
      api_get :show, id: state.id
      expect(json_response.symbolize_keys.keys).to include(*attributes)
    end
  end
end
