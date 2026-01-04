class SuperAdmin::DashboardController < ApplicationController
  before_action :require_super_admin

  def index
    ActsAsTenant.current_tenant = nil
    @total_revenue = Order.sum(:total_amount)
    @total_platform_fees = PlatformFee.sum(:amount)
    @total_orders = Order.count
    @total_tenants = Tenant.count
  end
end
