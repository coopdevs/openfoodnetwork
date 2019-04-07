require 'spec_helper'

describe SuppliedProperties do
  let(:supplied_properties) { described_class.new(enterprise) }

  describe '#supplied_properties' do
    let(:property) { create(:property, presentation: 'One') }
    let(:duplicate_property) { create(:property, presentation: 'One') }
    let(:different_property) { create(:property, presentation: 'Two') }

    let(:enterprise) do
      create(:enterprise, properties: [duplicate_property, different_property])
    end

    before do
      product = create(:product, properties: [property])
      enterprise.supplied_products << product
    end

    it "removes duplicate product and producer properties" do
      properties = supplied_properties.all
      expect(properties).to eq([duplicate_property, different_property])
    end
  end
end
