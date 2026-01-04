require 'rails_helper'

RSpec.describe 'Order Race Condition', type: :model do
  # This test simulates a race condition where two customers try to buy
  # the last item in stock at the exact same time.
  # The test proves that pessimistic locking prevents overselling.

  describe 'concurrent order placement with stock of 1' do
    it 'prevents overselling when two customers order simultaneously' do
      # Setup: Create a tenant, product with stock of 1, and two customers
      ActsAsTenant.current_tenant = nil
      tenant = Tenant.create!(name: 'Test Shop', subdomain: 'testshop')
      
      ActsAsTenant.current_tenant = tenant
      product = Product.create!(
        name: 'Limited Item',
        price: 100.00,
        stock_quantity: 1
      )

      customer1 = User.create!(
        email: 'customer1@test.com',
        password: 'password123',
        role: 'customer',
        tenant: tenant
      )

      customer2 = User.create!(
        email: 'customer2@test.com',
        password: 'password123',
        role: 'customer',
        tenant: tenant
      )

      # Verify initial state
      expect(product.reload.stock_quantity).to eq(1)

      # Simulate concurrent order attempts
      order1_success = false
      order2_success = false
      order1_error = nil
      order2_error = nil

      # Use threads to simulate concurrent requests
      thread1 = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ActsAsTenant.current_tenant = tenant
          begin
            ActiveRecord::Base.transaction do
              # Use pessimistic locking
              product = Product.find(product.id)
              product.with_lock do
                if product.stock_quantity >= 1
                  product.decrement!(:stock_quantity, 1)
                  order = Order.create!(
                    tenant: tenant,
                    user: customer1,
                    total_amount: product.price,
                    status: 'completed'
                  )
                  OrderItem.create!(
                    order: order,
                    product: product,
                    quantity: 1,
                    price: product.price
                  )
                  order.create_platform_fee!
                  order1_success = true
                else
                  raise 'Insufficient stock'
                end
              end
            end
          rescue StandardError => e
            order1_error = e.message
          end
        end
      end

      thread2 = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ActsAsTenant.current_tenant = tenant
          begin
            ActiveRecord::Base.transaction do
              # Use pessimistic locking
              product = Product.find(product.id)
              product.with_lock do
                if product.stock_quantity >= 1
                  product.decrement!(:stock_quantity, 1)
                  order = Order.create!(
                    tenant: tenant,
                    user: customer2,
                    total_amount: product.price,
                    status: 'completed'
                  )
                  OrderItem.create!(
                    order: order,
                    product: product,
                    quantity: 1,
                    price: product.price
                  )
                  order.create_platform_fee!
                  order2_success = true
                else
                  raise 'Insufficient stock'
                end
              end
            end
          rescue StandardError => e
            order2_error = e.message
          end
        end
      end

      # Wait for both threads to complete
      thread1.join
      thread2.join

      # Verify results
      product.reload
      
      # Exactly one order should succeed
      expect(order1_success || order2_success).to be true
      expect(order1_success && order2_success).to be false
      
      # Stock should be 0 (not negative)
      expect(product.stock_quantity).to eq(0)
      
      # Exactly one order should exist
      total_orders = Order.count
      expect(total_orders).to eq(1)
      
      # Verify platform fee was created
      expect(PlatformFee.count).to eq(1)
    end
  end

  describe 'concurrent order placement with sufficient stock' do
    it 'allows multiple orders when stock is sufficient' do
      # Setup: Create a tenant, product with stock of 2, and two customers
      ActsAsTenant.current_tenant = nil
      tenant = Tenant.create!(name: 'Test Shop 2', subdomain: 'testshop2')
      
      ActsAsTenant.current_tenant = tenant
      product = Product.create!(
        name: 'Available Item',
        price: 50.00,
        stock_quantity: 2
      )

      customer1 = User.create!(
        email: 'customer3@test.com',
        password: 'password123',
        role: 'customer',
        tenant: tenant
      )

      customer2 = User.create!(
        email: 'customer4@test.com',
        password: 'password123',
        role: 'customer',
        tenant: tenant
      )

      # Simulate concurrent order attempts
      order1_success = false
      order2_success = false

      thread1 = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ActsAsTenant.current_tenant = tenant
          begin
            ActiveRecord::Base.transaction do
              product = Product.find(product.id)
              product.with_lock do
                if product.stock_quantity >= 1
                  product.decrement!(:stock_quantity, 1)
                  order = Order.create!(
                    tenant: tenant,
                    user: customer1,
                    total_amount: product.price,
                    status: 'completed'
                  )
                  OrderItem.create!(
                    order: order,
                    product: product,
                    quantity: 1,
                    price: product.price
                  )
                  order.create_platform_fee!
                  order1_success = true
                end
              end
            end
          rescue StandardError => e
            # Ignore errors for this test
          end
        end
      end

      thread2 = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ActsAsTenant.current_tenant = tenant
          begin
            ActiveRecord::Base.transaction do
              product = Product.find(product.id)
              product.with_lock do
                if product.stock_quantity >= 1
                  product.decrement!(:stock_quantity, 1)
                  order = Order.create!(
                    tenant: tenant,
                    user: customer2,
                    total_amount: product.price,
                    status: 'completed'
                  )
                  OrderItem.create!(
                    order: order,
                    product: product,
                    quantity: 1,
                    price: product.price
                  )
                  order.create_platform_fee!
                  order2_success = true
                end
              end
            end
          rescue StandardError => e
            # Ignore errors for this test
          end
        end
      end

      thread1.join
      thread2.join

      product.reload
      
      # Both orders should succeed when stock is sufficient
      expect(order1_success).to be true
      expect(order2_success).to be true
      expect(product.stock_quantity).to eq(0)
      expect(Order.count).to eq(2)
      expect(PlatformFee.count).to eq(2)
    end
  end
end

