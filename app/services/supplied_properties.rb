class SuppliedProperties
  def initialize(enterprise)
    @enterprise = enterprise
  end

  def all
    (product_properties + producer_properties).uniq do |property_object|
      property_object.property.presentation
    end
  end

  private

  attr_reader :enterprise

  def product_properties
    products_including_properties = enterprise.supplied_products.includes(:properties)
    products_including_properties.flat_map(&:properties)
  end

  def producer_properties
    enterprise.properties
  end
end
