require 'rails_helper'

RSpec.describe Product, type: :model do
  let(:tenant) { Tenant.create!(name: 'Shop', subdomain: 'shop') }
  
  before { ActsAsTenant.current_tenant = tenant }

  describe 'validations' do
    it 'validates presence of name' do
      product = Product.new(name: nil)
      expect(product).not_to be_valid
    end

    it 'validates price greater than 0' do
      product = Product.new(name: 'Item', price: 0)
      expect(product).not_to be_valid
      
      product.price = 10
      expect(product).to be_valid
    end

    it 'validates stock greater than or equal to 0' do
      product = Product.new(name: 'Item', price: 10, stock_quantity: -1)
      expect(product).not_to be_valid
      
      product.stock_quantity = 0
      expect(product).to be_valid
    end
  end

  describe 'scopes' do
    it 'returns only in_stock products' do
      in_stock = Product.create!(name: 'In Stock', price: 10, stock_quantity: 5)
      out_of_stock = Product.create!(name: 'Out', price: 10, stock_quantity: 0)
      
      expect(Product.in_stock).to include(in_stock)
      expect(Product.in_stock).not_to include(out_of_stock)
    end
  end

  describe 'methods' do
    let(:product) { Product.create!(name: 'Item', price: 10, stock_quantity: 5) }

    it 'checks availability' do
      expect(product.available?).to be true
      product.update(stock_quantity: 0)
      expect(product.available?).to be false
    end

    it 'decreases stock thread-safely' do
      expect(product.decrease_stock(2)).to be true
      expect(product.reload.stock_quantity).to eq(3)
    end

    it 'returns false if insufficient stock' do
      expect(product.decrease_stock(6)).to be false
      expect(product.reload.stock_quantity).to eq(5)
    end
  end
end
