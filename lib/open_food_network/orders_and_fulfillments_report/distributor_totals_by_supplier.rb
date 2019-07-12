module OpenFoodNetwork
  class OrdersAndFulfillmentsReport
    class  DistributorTotalsBySupplier
      delegate :find_variant, to: :context

      def initialize(context)
        @context = context
      end

      def header
        [
          I18n.t(:report_header_hub),
          I18n.t(:report_header_producer),
          I18n.t(:report_header_product),
          I18n.t(:report_header_variant),
          I18n.t(:report_header_amount),
          I18n.t(:report_header_curr_cost_per_unit),
          I18n.t(:report_header_total_cost),
          I18n.t(:report_header_total_shipping_cost),
          I18n.t(:report_header_shipping_method)
        ]
      end

      def rules
        [
          {
            group_by: proc { |line_item| line_item.order.distributor },
            sort_by: proc { |distributor| distributor.name },
            summary_columns: [
              proc { |_line_items| "" },
              proc { |_line_items| I18n.t('admin.reports.total') },
              proc { |_line_items| "" },
              proc { |_line_items| "" },
              proc { |_line_items| "" },
              proc { |_line_items| "" },
              proc { |line_items| line_items.sum(&:amount) },
              proc { |line_items| line_items.map(&:order).uniq.sum(&:ship_total) },
              proc { |_line_items| "" }
            ]
          },
          {
            group_by: proc { |line_item| find_variant(line_item.variant_id).product.supplier },
            sort_by: proc { |supplier| supplier.name }
          },
          {
            group_by: proc { |line_item| find_variant(line_item.variant_id).product },
            sort_by: proc { |product| product.name }
          },
          {
            group_by: proc { |line_item| find_variant(line_item.variant_id).full_name },
            sort_by: proc { |full_name| full_name }
          }
        ]
      end

      private

      attr_reader :context
    end
  end
end
