require 'rails_helper'

RSpec.describe "Customer Flow", type: :request do
  let(:tenant) { Tenant.create!(name: 'Cool Shop', subdomain: 'cool') }
  let(:customer) { User.create!(email: 'customer@test.com', password: 'password', role: 'customer') }
  let!(:product) { Product.create!(name: 'Gadget', price: 100, stock_quantity: 5, tenant: tenant) }

  before do
    sign_in customer, scope: :user
  end

  describe "Full Shopping Journey" do
    it "allows browsing shops, viewing products, and placing an order" do
      # 1. Landing page (Tenants list)
      get customer_tenants_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Cool Shop')

      # 2. View Products for a Shop
      get customer_tenant_products_path(tenant)
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Gadget')
      
      # 3. Place Order
      expect {
        post customer_orders_path, params: {
          order_items: [
            { product_id: product.id, quantity: 2 }
          ]
        }
      }.to change(Order, :count).by(1)
      
      order = Order.last
      expect(order.tenant).to eq(tenant)
      expect(order.total_amount).to eq(200) # 2 * 100
      
      # 4. Verify Stock Reduction
      expect(product.reload.stock_quantity).to eq(3) # 5 - 2
      
      # 5. Redirect to Order Show
      expect(response).to redirect_to(customer_order_path(order))
    end
  end
end
