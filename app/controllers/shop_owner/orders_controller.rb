class ShopOwner::OrdersController < ApplicationController
  before_action :require_shop_owner

  expose :orders, -> { current_user.tenant.orders.order(created_at: :desc) }
  expose :order

end
