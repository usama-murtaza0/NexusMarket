# Nexus Market - Multi-Tenant SaaS E-commerce Platform

A comprehensive multi-tenant SaaS e-commerce platform built with Ruby on Rails, featuring row-level multi-tenancy, stock locking mechanisms, and role-based access control.

## Features

### Platform Admin (Super Admin)
- Create and manage tenants (shops)
- Global dashboard showing:
  - Total revenue across all shops
  - Total platform fees collected
  - Total orders and tenants

### Shop Owners
- CRUD operations for products (Name, Price, Stock Quantity)
- View orders for their shop
- Complete tenant isolation - cannot see other shops' data

### Customers
- Browse products in their shop
- Place orders with real-time stock checking
- View order history

### Technical Features
- **Row-Level Multi-Tenancy**: All data is scoped by `tenant_id` using `acts_as_tenant`
- **Stock Locking**: Pessimistic locking prevents overselling when multiple customers order simultaneously
- **Platform Fees**: Automatic 5% commission calculation on each order
- **Authentication & Authorization**: Devise-based authentication with role-based access control

## Setup

### Prerequisites
- Ruby 3.2.3 or higher
- Rails 8.0.4 or higher
- PostgreSQL 12 or higher

### Installation

1. Ensure PostgreSQL is installed and running:
```bash
# On macOS with Homebrew:
brew install postgresql@16
brew services start postgresql@16

# On Ubuntu/Debian:
sudo apt-get install postgresql postgresql-contrib
sudo systemctl start postgresql
```

2. Install dependencies:
```bash
bundle install
```

3. Set up the database:
```bash
rails db:create
rails db:migrate
```

4. (Optional) Create seed data for testing:
```bash
rails console
```

Then run:
```ruby
# Create a super admin
super_admin = User.create!(
  email: 'admin@nexusmarket.com',
  password: 'password123',
  role: 'super_admin'
)

# Create a tenant (shop)
tenant = Tenant.create!(
  name: 'Demo Shop',
  subdomain: 'demoshop'
)

# Create a shop owner
shop_owner = User.create!(
  email: 'owner@demoshop.com',
  password: 'password123',
  role: 'shop_owner',
  tenant: tenant
)

# Create a customer
customer = User.create!(
  email: 'customer@demoshop.com',
  password: 'password123',
  role: 'customer'
)

# Create some products
ActsAsTenant.current_tenant = tenant
Product.create!(name: 'Laptop', price: 999.99, stock_quantity: 5)
Product.create!(name: 'Mouse', price: 29.99, stock_quantity: 10)
Product.create!(name: 'Keyboard', price: 79.99, stock_quantity: 1)
```

5. Start the server:
```bash
rails server
```

6. Visit `http://localhost:3000`

### Test Credentials

After running the seed data above, you can login with:

- **Super Admin**: `admin@nexusmarket.com` / `password123`
- **Shop Owner**: `owner@demoshop.com` / `password123`
- **Customer**: `customer@demoshop.com` / `password123`

## Code Organization

### Namespaced Controllers

The application uses Rails namespacing to organize controllers by user role:

```
app/controllers/
├── application_controller.rb    # Base controller with authentication
├── customer/
│   ├── orders_controller.rb     # Customer order placement
│   └── products_controller.rb   # Customer product browsing
├── shop_owner/
│   ├── orders_controller.rb     # View shop orders
│   └── products_controller.rb   # CRUD for products
└── super_admin/
    ├── dashboard_controller.rb  # Global statistics
    ├── tenants_controller.rb    # Tenant management
    └── users_controller.rb      # User management
```

Each namespace has a `before_action` filter to ensure proper authorization:
- `Customer::*` → `before_action :require_customer`
- `ShopOwner::*` → `before_action :require_shop_owner`
- `SuperAdmin::*` → `before_action :require_super_admin`

### Decent Exposure Pattern

The application uses the `decent_exposure` gem for clean, declarative controller code:

```ruby
class ShopOwner::ProductsController < ApplicationController
  expose :products, -> { Product.all }
  expose :product
  
  def index
    # @products automatically available in view
  end
  
  def show
    # @product automatically loaded by ID from params
  end
end
```

This eliminates repetitive instance variable assignments and makes controllers more readable.

## Testing

Run the race condition test to verify stock locking:
```bash
bundle exec rspec spec/models/order_race_condition_spec.rb
```

Run all tests:
```bash
bundle exec rspec
```

## User Roles

The application supports three user roles:

1. **super_admin**: Platform administrators who can create tenants and view global statistics
2. **shop_owner**: Shop owners who manage products and view orders for their shop
3. **customer**: Customers who browse and purchase products

## Architecture Notes

### Concurrency & Locking Strategy

The application implements **pessimistic locking** to prevent race conditions and ensure data integrity when multiple customers attempt to purchase the same product simultaneously.

#### The Problem

Consider this scenario:
- A product has **1 item** in stock
- **Customer A** and **Customer B** both click "Buy" at the exact same millisecond
- Without proper locking, both transactions could:
  1. Read stock_quantity = 1 ✅
  2. Check if 1 >= 1 ✅
  3. Decrement stock to 0
  4. Create order ✅
- **Result**: 2 orders created, stock = -1 ❌ **OVERSOLD!**

#### The Solution: Pessimistic Locking

Our implementation uses database-level row locks to prevent this:

```ruby
# app/controllers/customer/orders_controller.rb
ActiveRecord::Base.transaction do
  items_params.each do |item_params|
    product = Product.find(item_params[:product_id])
    
    # Acquire exclusive lock on this product row
    product.with_lock do
      if product.stock_quantity >= quantity
        product.decrement!(:stock_quantity, quantity)
        # ... create order items
      else
        raise "Insufficient stock for #{product.name}"
      end
    end
  end
end
```

#### How It Works

1. **Transaction Boundary**: `ActiveRecord::Base.transaction` ensures atomicity - either all operations succeed or all rollback
2. **Row Lock**: `product.with_lock` acquires a `SELECT ... FOR UPDATE` lock on the product row
3. **Exclusive Access**: Other transactions attempting to lock the same product must wait
4. **Sequential Processing**: 
   - Customer A's transaction locks the product first
   - Customer B's transaction waits
   - Customer A decrements stock to 0 and commits
   - Customer B's transaction proceeds, sees stock = 0, raises error
5. **Automatic Rollback**: If any error occurs, the entire transaction rolls back

#### Visual Flow

```
Time →
Customer A: [Lock Product] → [Check Stock=1] → [Decrement to 0] → [Create Order] → [Commit]
Customer B:                   [Waiting...]                                         [Lock Product] → [Check Stock=0] → [Error!]
```

#### Proof: Race Condition Test

See `spec/models/order_race_condition_spec.rb` for a comprehensive test that:
- Creates a product with stock of 1
- Spawns 2 concurrent threads simulating simultaneous purchases
- Verifies exactly 1 order succeeds (not both)
- Verifies stock never goes negative
- Proves the locking mechanism works under real concurrency

Run the test:
```bash
bundle exec rspec spec/models/order_race_condition_spec.rb
```

### Cross-Tenant Commission Logic

The platform charges a **5% commission** on every order. This commission tracking is intentionally designed to work across tenant boundaries.

#### Design Decision: Global Platform Fees

Unlike other models (Products, Orders), the `PlatformFee` model is **NOT tenant-scoped**:

```ruby
# app/models/platform_fee.rb
class PlatformFee < ApplicationRecord
  belongs_to :order
  belongs_to :tenant
  
  # Platform fees are NOT tenant-scoped - they're global
  # We don't use acts_as_tenant here
end
```

#### Why Not Tenant-Scoped?

1. **Super Admin Reporting**: Platform administrators need to see total fees across ALL tenants
2. **Cross-Tenant Aggregation**: Enables queries like "total platform revenue this month"
3. **Audit Trail**: Maintains a global record of all commissions for financial reporting
4. **Tenant Reference**: Still stores `tenant_id` for attribution, but doesn't filter by it

#### Implementation

When an order is completed, a platform fee is automatically created:

```ruby
# app/models/order.rb
PLATFORM_FEE_PERCENTAGE = 0.05 # 5%

def create_platform_fee!
  fee_amount = calculate_platform_fee
  PlatformFee.create!(
    order: self,
    tenant: tenant,  # Store which tenant generated this fee
    amount: fee_amount
  )
end
```

#### Super Admin Dashboard

The super admin can view global statistics without tenant filtering:

```ruby
# app/controllers/super_admin/dashboard_controller.rb
def index
  ActsAsTenant.current_tenant = nil  # Bypass tenant scoping
  @total_revenue = Order.sum(:total_amount)
  @total_platform_fees = PlatformFee.sum(:amount)  # Cross-tenant sum
  @total_orders = Order.count
  @total_tenants = Tenant.count
end
```

#### Example Scenario

```
Tenant A (Shop 1):
  - Order #1: $100 → Platform Fee: $5
  - Order #2: $200 → Platform Fee: $10

Tenant B (Shop 2):
  - Order #3: $150 → Platform Fee: $7.50

Super Admin Dashboard:
  - Total Revenue: $450
  - Total Platform Fees: $22.50 (across all tenants)
```

### Multi-Tenancy Implementation

The application implements row-level multi-tenancy using the `acts_as_tenant` gem:

#### Tenant Scoping

All tenant-scoped models automatically filter by `tenant_id`:

```ruby
# app/models/order.rb
class Order < ApplicationRecord
  acts_as_tenant :tenant  # Automatically scopes all queries
end
```

When a shop owner is logged in:
```ruby
# app/controllers/application_controller.rb
def set_current_tenant
  if current_user&.super_admin?
    ActsAsTenant.current_tenant = nil  # Super admins see everything
  elsif current_user&.tenant_id.present?
    ActsAsTenant.current_tenant = current_user.tenant  # Scope to user's tenant
  end
end
```

#### Data Isolation

- **Shop Owners**: Can only see/manage products and orders for their tenant
- **Customers**: Can only see products and create orders within their tenant
- **Super Admins**: Can bypass tenant scoping to manage all tenants

#### Tenant-Scoped Models

- ✅ `Product` - Each shop has its own product catalog
- ✅ `Order` - Orders belong to a specific tenant
- ✅ `User` - Users are associated with a tenant (except super_admin)
- ❌ `PlatformFee` - Intentionally global for cross-tenant reporting

## Gems Used

- **devise**: Authentication
- **acts_as_tenant**: Multi-tenancy
- **slim-rails**: Slim templating engine
- **bootstrap**: Frontend framework
- **decent_exposure**: Clean controller code
- **rspec-rails**: Testing framework
- **factory_bot_rails**: Test fixtures

## Database Schema

- **users**: Authentication and user management (with role and tenant_id)
- **tenants**: Shop/tenant information
- **products**: Product catalog (tenant-scoped)
- **orders**: Customer orders (tenant-scoped)
- **order_items**: Order line items
- **platform_fees**: Platform commission tracking (global, not tenant-scoped)

## License

This project is part of a technical demonstration.
