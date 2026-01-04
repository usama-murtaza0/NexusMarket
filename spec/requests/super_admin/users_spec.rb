require 'rails_helper'

RSpec.describe "SuperAdmin::Users", type: :request do
  let(:super_admin) { User.create!(email: 'admin@test.com', password: 'password', role: 'super_admin') }
  let(:tenant) { Tenant.create!(name: 'Test Shop', subdomain: 'test') }
  
  before do
    sign_in super_admin, scope: :user
  end

  describe "POST /create" do
    it "creates a new user" do
      expect {
        post super_admin_users_path, params: { 
          user: { 
            email: "new@test.com", 
            role: "shop_owner", 
            tenant_id: tenant.id 
          } 
        }
      }.to change(User, :count).by(1)
      
      user = User.last
      expect(user.role).to eq('shop_owner')
      expect(user.tenant).to eq(tenant)
      expect(user.encrypted_password).to be_present # Auto-generated password
    end
  end
end
