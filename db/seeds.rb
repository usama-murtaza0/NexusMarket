# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create Super Admin User
# Super admins have access to everything - they can create tenants, view global dashboard,
# and manage all aspects of the platform without tenant restrictions
ActsAsTenant.current_tenant = nil

super_admin = User.find_or_initialize_by(email: 'super@admin.com')
if super_admin.new_record?
  super_admin.assign_attributes(
    password: '123123',
    password_confirmation: '123123',
    role: 'super_admin',
    tenant_id: nil  # Super admins don't belong to any tenant
  )
  super_admin.save!
  puts "✓ Created super admin user: super@admin.com"
else
  # Update existing user to ensure correct role and no tenant
  super_admin.update!(
    role: 'super_admin',
    tenant_id: nil
  )
  puts "✓ Super admin user already exists: super@admin.com"
end

puts "\n=== Seed Data Summary ==="
puts "Super Admin User:"
puts "  Email: super@admin.com"
puts "  Password: 123123"
puts "  Role: super_admin"
puts "  Access: Full platform access (can create tenants, view global dashboard, manage all data)"
puts "\nYou can now login with these credentials to access the super admin dashboard."
