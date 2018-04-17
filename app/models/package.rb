module OpenFoodNetwork
  class Package < SimpleDelegator
    def initialize(package, distributor)
      super(package)
      @distributor = distributor
    end

    def shipping_methods
      super.each do |shipping_method|
        distributes_with?(shipping_method)
      end
    end

    private

    attr_reader :distributor

    def distributes_with?(shipping_method)
      shipping_method.distributors.include?(distributor)
    end
  end
end
