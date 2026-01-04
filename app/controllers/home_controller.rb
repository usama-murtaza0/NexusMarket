class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]

  def index
    if user_signed_in?
      case current_user.role
      when 'super_admin'
        redirect_to super_admin_dashboard_index_path
      when 'shop_owner'
        redirect_to shop_owner_products_path
      when 'customer'
        redirect_to customer_products_path
      end
    end
  end
end
