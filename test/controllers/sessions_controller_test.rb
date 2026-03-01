require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "should get login page" do
    get login_path
    assert_response :success
  end

  test "should redirect login page when already logged in" do
    log_in_as(@user)
    get login_path
    assert_redirected_to root_path
  end

  test "should log in with valid credentials" do
    post login_path, params: { email: @user.email, password: "password123" }
    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
  end

  test "should reject invalid password" do
    post login_path, params: { email: @user.email, password: "wrong" }
    assert_response :unprocessable_entity
  end

  test "should reject nonexistent email" do
    post login_path, params: { email: "nobody@example.com", password: "password123" }
    assert_response :unprocessable_entity
  end

  test "should log out" do
    log_in_as(@user)
    delete logout_path
    assert_redirected_to login_path
  end

  test "should redirect to login when accessing protected page" do
    get root_path
    assert_redirected_to login_path
  end

  test "should store forwarding URL and redirect back after login" do
    get root_path
    assert_redirected_to login_path

    post login_path, params: { email: @user.email, password: "password123" }
    assert_redirected_to root_url
  end
end
