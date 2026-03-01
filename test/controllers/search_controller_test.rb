require "test_helper"

class SearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @vault = @user.personal_vault
    @folder = folders(:general_one)
    log_in_as(@user)

    mek = derive_mek_for_user(@user)
    encrypted = Encryption::SecretEncryptionService.encrypt(value: "x", key: mek)
    @secret = Secret.create!(
      folder: @folder, vault: @vault, name: "GitHub Token",
      service_name: "GitHub", tags: "ci",
      encrypted_value: encrypted[:encrypted_value],
      encrypted_value_iv: encrypted[:iv],
      encrypted_value_auth_tag: encrypted[:auth_tag]
    )
  end

  test "should get index" do
    get search_url
    assert_response :success
  end

  test "should search by query" do
    get search_url, params: { q: "GitHub" }
    assert_response :success
    assert_select "h3", text: /GitHub Token/
  end

  test "should return no results for non-matching query" do
    get search_url, params: { q: "nonexistent" }
    assert_response :success
    assert_select "h3", text: "No results found"
  end

  test "should respond to turbo stream" do
    get search_url, params: { q: "GitHub" }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
  end

  test "should redirect to login when not logged in" do
    delete logout_url
    get search_url
    assert_redirected_to login_url
  end

  private

  def derive_mek_for_user(user)
    pdk = Encryption::KeyDerivationService.derive_key(password: "password123", salt: user.master_key_salt)
    Encryption::MasterKeyService.unwrap(wrapped_key: user.encrypted_master_key, wrapping_key: pdk)
  end
end
