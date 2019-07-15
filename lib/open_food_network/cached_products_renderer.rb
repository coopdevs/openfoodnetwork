require 'open_food_network/products_renderer'

# Wrapper for ProductsRenderer that caches the JSON output.
# ProductsRenderer::NoProducts is represented in the cache as nil,
# but re-raised to provide the same interface as ProductsRenderer.

module OpenFoodNetwork
  class CachedProductsRenderer
    class NoProducts < RuntimeError; end

    def initialize(distributor, order_cycle)
      @distributor = distributor
      @order_cycle = order_cycle
    end

    def products_json
      raise NoProducts, I18n.t(:no_products) if @distributor.nil? || @order_cycle.nil?

      products_json = cached_products_json

      raise NoProducts, I18n.t(:no_products) if products_json.nil?

      products_json
    end

    private

    # TODO: Paginate including request params in the key so that we end up with
    # a cache entry per page, items per page, etc.
    def cached_products_json
      return uncached_products_json unless use_cached_products?

      Rails.cache.fetch("products-json-#{@distributor.id}-#{@order_cycle.id}") do
        begin
          uncached_products_json
        rescue ProductsRenderer::NoProducts
          nil
        end
      end
    end

    def use_cached_products?
      Spree::Config[:enable_products_cache?]
    end

    def uncached_products_json
      ProductsRenderer.new(@distributor, @order_cycle).products_json
    end
  end
end
