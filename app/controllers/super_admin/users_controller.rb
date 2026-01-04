class SuperAdmin::UsersController < ApplicationController
  before_action :require_super_admin

  expose :users, -> { User.all.order(created_at: :desc) }
  expose :user
  expose :tenants, -> { Tenant.all.order(:name) }

  def new
    @tenants = Tenant.all.order(:name)
  end

  def create
    user = User.new(user_params)

    if user.password.blank?
      user.password = SecureRandom.hex(8)
      user.password_confirmation = user.password
    end
    
    if user.save
      redirect_to super_admin_users_path, notice: 'User created successfully'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @tenants = Tenant.all.order(:name)
  end

  def update
    update_params = user_params

    if update_params[:password].blank?
      update_params.delete(:password)
      update_params.delete(:password_confirmation)
    end
    
    if user.update(update_params)
      redirect_to super_admin_users_path, notice: 'User updated successfully'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if user == current_user
      redirect_to super_admin_users_path, alert: 'You cannot delete your own account'
    else
      user.destroy
      redirect_to super_admin_users_path, notice: 'User deleted successfully'
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :role, :tenant_id)
  end
end
