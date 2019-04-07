class SuppliedProperties
  def initialize(enterprise)
    @enterprise = enterprise
  end

  def all
    (product_properties + producer_properties).uniq(&:presentation)
  end

  private

  attr_reader :enterprise

  def product_properties
    Spree::Property
      .select('DISTINCT spree_properties.*')
      .joins(products: :supplier)
      .merge(enterprise.supplied_products)
  end

  def producer_properties
    enterprise.properties
  end
end
