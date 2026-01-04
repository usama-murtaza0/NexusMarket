require "test_helper"

class SuperAdmin::TenantsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get super_admin_tenants_index_url
    assert_response :success
  end

  test "should get create" do
    get super_admin_tenants_create_url
    assert_response :success
  end

  test "should get new" do
    get super_admin_tenants_new_url
    assert_response :success
  end
end
