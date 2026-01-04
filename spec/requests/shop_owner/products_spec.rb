require 'rails_helper'

RSpec.describe "ShopOwner::Products", type: :request do
  let(:tenant) { Tenant.create!(name: 'My Shop', subdomain: 'my-shop') }
  let(:shop_owner) { User.create!(email: 'owner@test.com', password: 'password', role: 'shop_owner', tenant: tenant) }
  
  before do
    sign_in shop_owner, scope: :user
  end

  describe "POST /create" do
    it "creates a product for the current tenant" do
      expect {
        post shop_owner_products_path, params: {
          product: {
            name: "New Product",
            price: 19.99,
            stock_quantity: 10
          }
        }
      }.to change(Product, :count).by(1)
      
      product = Product.last
      expect(product.tenant).to eq(tenant)
      expect(product.name).to eq("New Product")
    end
  end
  
  describe "GET /index" do
    it "lists products only for my tenant" do
      my_product = Product.create!(name: "Mine", price: 10, tenant: tenant)
      other_tenant = Tenant.create!(name: "Other", subdomain: "other")
      other_product = Product.create!(name: "Theirs", price: 10, tenant: other_tenant)
      
      get shop_owner_products_path
      expect(response.body).to include("Mine")
      expect(response.body).not_to include("Theirs")
    end
  end
end
