class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!
  before_action :set_current_tenant

  private

  def set_current_tenant
    if current_user&.super_admin?
      # Super admins can access without tenant scope
      ActsAsTenant.current_tenant = nil
    elsif current_user&.tenant_id.present?
      ActsAsTenant.current_tenant = current_user.tenant
    end
  end

  def require_super_admin
    redirect_to root_path, alert: 'Access denied' unless current_user&.super_admin?
  end

  def require_shop_owner
    redirect_to root_path, alert: 'Access denied' unless current_user&.shop_owner?
  end

  def require_customer
    redirect_to root_path, alert: 'Access denied' unless current_user&.customer?
  end
end
