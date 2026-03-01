require "test_helper"

class AuditEventTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @vault = vaults(:personal_one)
  end

  test "should be valid with valid attributes" do
    event = AuditEvent.new(
      user: @user,
      vault: @vault,
      action: "user.login",
      ip_address: "127.0.0.1"
    )
    assert event.valid?
  end

  test "should require action" do
    event = AuditEvent.new(user: @user, vault: @vault, action: nil)
    assert_not event.valid?
  end

  test "should validate action inclusion" do
    event = AuditEvent.new(user: @user, vault: @vault, action: "invalid.action")
    assert_not event.valid?
  end

  test "should require user" do
    event = AuditEvent.new(vault: @vault, action: "user.login")
    assert_not event.valid?
  end

  test "should require vault" do
    event = AuditEvent.new(user: @user, action: "user.login")
    assert_not event.valid?
  end

  test "should allow optional secret" do
    event = AuditEvent.new(
      user: @user,
      vault: @vault,
      action: "user.login",
      secret: nil
    )
    assert event.valid?
  end

  test "should be immutable after creation" do
    event = AuditEvent.create!(
      user: @user,
      vault: @vault,
      action: "user.login",
      ip_address: "127.0.0.1"
    )

    assert_raises(ActiveRecord::ReadOnlyRecord) do
      event.update!(action: "user.logout")
    end
  end

  test "should not be destroyable" do
    event = AuditEvent.create!(
      user: @user,
      vault: @vault,
      action: "user.login"
    )

    assert_raises(ActiveRecord::ReadOnlyRecord) do
      event.destroy!
    end
  end
end
