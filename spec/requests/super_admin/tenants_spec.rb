require 'rails_helper'

RSpec.describe "SuperAdmin::Tenants", type: :request do
  let(:super_admin) { User.create!(email: 'admin@test.com', password: 'password', role: 'super_admin') }
  
  before do
    sign_in super_admin, scope: :user
  end

  describe "GET /index" do
    it "returns http success" do
      get super_admin_tenants_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /create" do
    it "creates a new tenant" do
      expect {
        post super_admin_tenants_path, params: { tenant: { name: "New Shop", subdomain: "new-shop" } }
      }.to change(Tenant, :count).by(1)
      expect(response).to redirect_to(super_admin_tenants_path)
    end

    it "renders new on invalid inputs" do
      post super_admin_tenants_path, params: { tenant: { name: "", subdomain: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /update" do
    let!(:tenant) { Tenant.create!(name: "Old Name", subdomain: "old-name") }

    it "updates the tenant" do
      patch super_admin_tenant_path(tenant), params: { tenant: { name: "New Name" } }
      expect(tenant.reload.name).to eq("New Name")
      expect(response).to redirect_to(super_admin_tenants_path)
    end
  end

  describe "DELETE /destroy" do
    let!(:tenant) { Tenant.create!(name: "To Delete", subdomain: "delete-me") }

    it "deletes the tenant" do
      expect {
        delete super_admin_tenant_path(tenant)
      }.to change(Tenant, :count).by(-1)
      expect(response).to redirect_to(super_admin_tenants_path)
    end
  end
end
