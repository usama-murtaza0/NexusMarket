require 'rails_helper'

RSpec.describe Tenant, type: :model do
  describe 'validations' do
    it 'validates presence of name' do
      tenant = Tenant.new(name: nil)
      expect(tenant).not_to be_valid
      expect(tenant.errors[:name]).to include("can't be blank")
    end

    it 'validates presence of subdomain' do
      tenant = Tenant.new(subdomain: nil)
      expect(tenant).not_to be_valid
      expect(tenant.errors[:subdomain]).to include("can't be blank")
    end

    it 'validates uniqueness of subdomain' do
      Tenant.create!(name: 'Existing', subdomain: 'existing')
      duplicate = Tenant.new(name: 'New', subdomain: 'existing')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:subdomain]).to include('has already been taken')
    end

    it 'validates format of subdomain' do
      invalid_tenant = Tenant.new(name: 'Bad', subdomain: 'Invalid Subdomain')
      expect(invalid_tenant).not_to be_valid
      expect(invalid_tenant.errors[:subdomain]).to include('is invalid')

      valid_tenant = Tenant.new(name: 'Good', subdomain: 'valid-subdomain-123')
      expect(valid_tenant).to be_valid
    end
  end

  describe 'normalization' do
    it 'downcases and strips subdomain' do
      tenant = Tenant.create!(name: 'Test', subdomain: '  Test-Subdomain  ')
      expect(tenant.subdomain).to eq('test-subdomain')
    end
  end

  describe 'associations' do
    it { should have_many(:users).dependent(:destroy) }
    it { should have_many(:products).dependent(:destroy) }
    it { should have_many(:orders).dependent(:destroy) }
  end
end
