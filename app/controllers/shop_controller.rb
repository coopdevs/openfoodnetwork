require 'open_food_network/cached_products_renderer'

class ShopController < BaseController
  layout "darkswarm"
  before_filter :require_distributor_chosen, :set_order_cycles, except: :changeable_orders_alert
  before_filter :enable_embedded_shopfront

  def show
    redirect_to main_app.enterprise_shop_path(current_distributor)
  end

  def products
    renderer = OpenFoodNetwork::CachedProductsRenderer.new(
      current_distributor,
      current_order_cycle
    )

    products = paginate(renderer.products_json)

    # I expected @distributor to be nil but it is not. @distributor ==
    # current_distributor => true
    serializer = ActiveModel::ArraySerializer.new(
      products,
      each_serializer: Api::ProductSerializer,
      current_order_cycle: current_order_cycle,
      current_distributor: @distributor,
      variants: variants_for_shop_by_id,
      master_variants: master_variants_for_shop_by_id,
      enterprise_fee_calculator: OpenFoodNetwork::EnterpriseFeeCalculator.new(
        @distributor,
        current_order_cycle
      )
    )

    render json: serializer
  rescue OpenFoodNetwork::CachedProductsRenderer::NoProducts
    render status: :not_found, json: ''
  end

  def order_cycle
    if request.post?
      if oc = OrderCycle.with_distributor(@distributor).active.find_by_id(params[:order_cycle_id])
        current_order(true).set_order_cycle! oc
        @current_order_cycle = oc
        render partial: "json/order_cycle"
      else
        render status: :not_found, json: ""
      end
    else
      render partial: "json/order_cycle"
    end
  end

  def changeable_orders_alert
    render layout: false
  end

  private

  def all_variants_for_shop
    # We use the in_stock? method here instead of the in_stock scope because we need to
    # look up the stock as overridden by VariantOverrides, and the scope method is not affected
    # by them.
    scoper = OpenFoodNetwork::ScopeVariantToHub.new(@distributor)
    Spree::Variant.
      for_distribution(current_order_cycle, @distributor).
      each { |v| scoper.scope(v) }.
      select(&:in_stock?)
  end


  def variants_for_shop_by_id
    index_by_product_id all_variants_for_shop.reject(&:is_master)
  end

  def master_variants_for_shop_by_id
    index_by_product_id all_variants_for_shop.select(&:is_master)
  end

  def index_by_product_id(variants)
    variants.each_with_object({}) do |v, vs|
      vs[v.product_id] ||= []
      vs[v.product_id] << v
    end
  end

  def filtered_json(products_json)
    if applicator.rules.any?
      filter(products_json)
    else
      products_json
    end
  end

  def filter(products_hash)
    applicator.filter!(products_hash)
  end

  def applicator
    return @applicator unless @applicator.nil?
    @applicator = OpenFoodNetwork::TagRuleApplicator.new(
      current_distributor,
      "FilterProducts",
      current_customer.andand.tag_list
    )
  end
end
