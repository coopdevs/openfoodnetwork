module OpenFoodNetwork
  class Package < SimpleDelegator
    def shipping_methods
      byebug
      super.select do |shipping_method|
        distributes_with?(shipping_method)
      end
    end

    private

    def distributes_with?(shipping_method)
      shipping_method.distributors.include?(order.distributor)
    end
  end
end
