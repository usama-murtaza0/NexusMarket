class SuperAdmin::TenantsController < ApplicationController
  before_action :require_super_admin

  expose :tenants, -> { Tenant.all }
  expose :tenant

  def create
    tenant = Tenant.new(tenant_params)
    if tenant.save
      redirect_to super_admin_tenants_path, notice: 'Tenant created successfully'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if tenant.update(tenant_params)
      redirect_to super_admin_tenants_path, notice: 'Tenant updated successfully'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    tenant.destroy
    redirect_to super_admin_tenants_path, notice: 'Tenant deleted successfully'
  end

  private

  def tenant_params
    params.require(:tenant).permit(:name, :subdomain)
  end
end
