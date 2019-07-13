require 'open_food_network/scope_product_to_hub'

module OpenFoodNetwork
  class ProductsRenderer
    class NoProducts < RuntimeError; end

    def initialize(distributor, order_cycle)
      @distributor = distributor
      @order_cycle = order_cycle
    end

    def products_json
      products = load_products

      if products
        products
      else
        raise NoProducts
      end
    end

    private

    # TODO: There can't be any #select. The result set returned by Postgres
    # must be what we paginate. Pagination is all based around SQL.
    def load_products
      return unless @order_cycle
      scoper = ScopeProductToHub.new(@distributor)

      OrderCycleDistributedProducts.new(@order_cycle, @distributor).
        relation.
        order(taxon_order).
        each { |product| scoper.scope(product) }.
        select do |product|
          # TODO: Move this deleted check within the query
          # TODO: Move has_stock_for_distribution within the query
          !product.deleted? && product.has_stock_for_distribution?(@order_cycle, @distributor)
        end
    end

    def taxon_order
      if @distributor.preferred_shopfront_taxon_order.present?
        @distributor
          .preferred_shopfront_taxon_order
          .split(",").map { |id| "primary_taxon_id=#{id} DESC" }
          .join(",") + ", name ASC"
      else
        "name ASC"
      end
    end
  end
end
