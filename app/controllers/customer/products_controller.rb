class Customer::ProductsController < ApplicationController
  before_action :require_customer

  expose :tenant, -> { Tenant.find(params[:tenant_id]) }
  expose :products, -> { tenant.products.in_stock }
  expose :product

  def show
    order_item = { product_id: product.id, quantity: 1 }
  end
end
