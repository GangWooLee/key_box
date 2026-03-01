require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "should get signup page" do
    get signup_path
    assert_response :success
  end

  test "should redirect signup page when already logged in" do
    log_in_as(users(:one))
    get signup_path
    assert_redirected_to root_path
  end

  test "should create user with valid params" do
    assert_difference "User.count", 1 do
      post signup_path, params: {
        user: {
          name: "New User",
          email: "newuser@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
  end

  test "should create vault and folder on signup" do
    assert_difference [ "Vault.count", "Folder.count", "Membership.count" ], 1 do
      post signup_path, params: {
        user: {
          name: "Vault User",
          email: "vaultuser@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
  end

  test "should not create user with invalid params" do
    assert_no_difference "User.count" do
      post signup_path, params: {
        user: {
          name: "",
          email: "invalid",
          password: "short",
          password_confirmation: "mismatch"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should not create user with duplicate email" do
    assert_no_difference "User.count" do
      post signup_path, params: {
        user: {
          name: "Duplicate",
          email: users(:one).email,
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_response :unprocessable_entity
  end
end
