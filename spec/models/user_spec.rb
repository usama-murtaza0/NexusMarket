require 'rails_helper'

RSpec.describe User, type: :model do
  let(:tenant) { Tenant.create!(name: 'Test Shop', subdomain: 'test') }

  describe 'validations' do
    it 'validates presence of role' do
      user = User.new
      user.role = nil
      expect(user).not_to be_valid
      expect(user.errors[:role]).to include("can't be blank")
    end

    it 'validates inclusion of role' do
      user = User.new(role: 'invalid_role')
      expect(user).not_to be_valid
    end

    it 'requires tenant for shop_owner' do
      user = User.new(role: 'shop_owner', email: 'owner@test.com', password: 'password', tenant: nil)
      expect(user).not_to be_valid
      expect(user.errors[:tenant_id]).to include('is required for Shop Owner users')
    end
  end

  describe 'defaults' do
    it 'sets default role to customer' do
      user = User.new
      expect(user.role).to eq('customer')
    end
  end

  describe 'helper methods' do
    it 'checks super_admin?' do
      user = User.new(role: 'super_admin')
      expect(user.super_admin?).to be true
      expect(user.shop_owner?).to be false
    end

    it 'checks shop_owner?' do
      user = User.new(role: 'shop_owner')
      expect(user.shop_owner?).to be true
    end

    it 'checks customer?' do
      user = User.new(role: 'customer')
      expect(user.customer?).to be true
    end
  end
end
