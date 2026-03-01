require "test_helper"

class AuditEventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @vault = @user.personal_vault
    log_in_as(@user)

    # Create some audit events
    3.times do |i|
      AuditEvent.create!(
        user: @user,
        vault: @vault,
        action: "secret.create",
        metadata: { name: "Secret #{i}" }
      )
    end
  end

  test "should get index" do
    get vault_audit_events_url(@vault)
    assert_response :success
  end

  test "should display audit events" do
    get vault_audit_events_url(@vault)
    assert_select "td", text: /secret\.create/
  end

  test "should paginate with page param" do
    get vault_audit_events_url(@vault, page: 1)
    assert_response :success
  end

  test "should redirect to login when not logged in" do
    delete logout_url
    get vault_audit_events_url(@vault)
    assert_redirected_to login_url
  end
end
