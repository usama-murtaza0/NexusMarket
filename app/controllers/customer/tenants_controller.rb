class Customer::TenantsController < ApplicationController
  before_action :require_customer

  expose :tenants, -> { Tenant.all.order(:name) }
  expose :tenant

  def index
  end

  def show
    redirect_to customer_tenant_products_path(tenant)
  end
end
