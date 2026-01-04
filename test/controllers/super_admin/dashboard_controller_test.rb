require "test_helper"

class SuperAdmin::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get super_admin_dashboard_index_url
    assert_response :success
  end
end
