require 'rails_helper'

RSpec.describe Order, type: :model do
  let(:tenant) { Tenant.create!(name: 'Shop', subdomain: 'shop') }
  let(:user) { User.create!(email: 'c@test.com', password: 'password', role: 'customer', tenant: tenant) }
  
  before { ActsAsTenant.current_tenant = tenant }

  describe 'platform fees' do
    it 'calculates 5% fee' do
      order = Order.new(total_amount: 100)
      expect(order.calculate_platform_fee).to eq(5.0)
    end

    it 'creates a platform fee record' do
      order = Order.create!(tenant: tenant, user: user, total_amount: 200, status: 'completed')
      
      expect {
        order.create_platform_fee!
      }.to change(PlatformFee, :count).by(1)
      
      fee = PlatformFee.last
      expect(fee.amount).to eq(10.0)
      expect(fee.tenant).to eq(tenant)
    end
  end
end
