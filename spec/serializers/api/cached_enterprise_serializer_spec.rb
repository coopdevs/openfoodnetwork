require 'spec_helper'

describe Api::CachedEnterpriseSerializer do
  let(:cached_enterprise_serializer) { described_class.new(enterprise) }
  let(:enterprise) { create(:enterprise) }

  describe '#supplied_properties' do
    let(:supplied_properties) { instance_double(SuppliedProperties, all: true) }
    let(:enterprise) { create(:enterprise) }

    before do
      allow(SuppliedProperties).to receive(:new).with(enterprise) { supplied_properties }
    end

    it "calls SuppliedProperties" do
      cached_enterprise_serializer.supplied_properties
      expect(supplied_properties).to have_received(:all)
    end
  end

  describe '#distributed_properties' do
    let(:cached_enterprise_serializer) { described_class.new(shop, options) }

    let(:shop) { create(:distributor_enterprise) }

    let(:options) { { data: enterprise_injection_data } }

    let(:property) { create(:property, presentation: 'One') }
    let(:duplicate_property) { create(:property, presentation: 'One') }
    let(:producer) { create(:supplier_enterprise, properties: [duplicate_property]) }

    before do
      product = create(:product, properties: [property])
      producer.supplied_products << product

      create(
        :simple_order_cycle,
        coordinator: shop,
        suppliers: [producer],
        distributors: [shop],
        variants: product.variants
      )
    end

    context 'when the enterprise is not an active distributor' do
      let(:enterprise_injection_data) do
        instance_double(OpenFoodNetwork::EnterpriseInjectionData, active_distributors: [])
      end

      it 'does not duplicate properties' do
        properties = cached_enterprise_serializer.distributed_properties
        expect(properties.map(&:presentation)).to eq([property.presentation])
      end

      it 'fetches producer properties' do
        distributed_producer_properties = cached_enterprise_serializer
          .distributed_producer_properties

        expect(distributed_producer_properties.map(&:presentation))
          .to eq(producer.producer_properties.map(&:property).map(&:presentation))
      end
    end

    context 'when the enterprise is an active distributor' do
      let(:enterprise_injection_data) do
        instance_double(OpenFoodNetwork::EnterpriseInjectionData, active_distributors: [shop])
      end

      it 'does not duplicate properties' do
        properties = cached_enterprise_serializer.distributed_properties
        expect(properties.map(&:presentation)).to eq([property.presentation])
      end

      it 'fetches producer properties' do
        distributed_producer_properties = cached_enterprise_serializer
          .distributed_producer_properties

        expect(distributed_producer_properties.map(&:presentation))
          .to eq(producer.producer_properties.map(&:property).map(&:presentation))
      end
    end
  end
end
