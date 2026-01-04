require "test_helper"

class ShopOwner::OrdersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get shop_owner_orders_index_url
    assert_response :success
  end

  test "should get show" do
    get shop_owner_orders_show_url
    assert_response :success
  end
end
