class Customer::OrdersController < ApplicationController
  before_action :require_customer

  expose :orders, -> { current_user.orders.order(created_at: :desc) }
  expose :order

  def create
    begin
      ActiveRecord::Base.transaction do
        items_params = order_items_params

        if items_params.empty?
          redirect_to customer_products_path, alert: 'No items in order'
          return
        end
        product = Product.find_by(id: items_params.first[:product_id])
          
        unless product
          redirect_to customer_products_path, alert: 'Product not found'
        end
          
        order = Order.new(
          tenant: product.tenant,
          user: current_user,
          total_amount: 0,
          status: 'pending'
        )

        total_amount = 0

        items_params.each do |item_params|
          product = Product.find(item_params[:product_id])
          quantity = item_params[:quantity].to_i

          if quantity <= 0
            raise "Invalid quantity for #{product.name}"
          end

          product.with_lock do
            if product.stock_quantity >= quantity
              product.decrement!(:stock_quantity, quantity)
              order_item = order.order_items.build(
                product: product,
                quantity: quantity,
                price: product.price
              )
              total_amount += order_item.subtotal
            else
              raise "Insufficient stock for #{product.name}"
            end
          end
        end

        if total_amount > 0
          order.total_amount = total_amount
          order.status = 'completed'
          order.save!
          order.create_platform_fee!
          redirect_to customer_order_path(order), notice: 'Order placed successfully'
        else
          redirect_to customer_products_path, alert: 'No items in order'
        end
      end
    rescue StandardError => e
      redirect_to customer_products_path, alert: "Order failed: #{e.message}"
    end
  end

  private

  def order_items_params
    params.permit(order_items: [:product_id, :quantity])[:order_items] || []
  end
end
