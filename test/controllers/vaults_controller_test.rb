require "test_helper"

class VaultsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "should redirect to login when not authenticated" do
    get root_path
    assert_redirected_to login_path
  end

  test "should show vault dashboard when logged in" do
    log_in_as(@user)
    get root_path
    assert_response :success
  end
end
