require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  setup do
    @membership = memberships(:alice_personal)
  end

  test "should be valid" do
    assert @membership.valid?
  end

  test "should require user" do
    @membership.user = nil
    assert_not @membership.valid?
  end

  test "should require vault" do
    @membership.vault = nil
    assert_not @membership.valid?
  end

  test "should enforce unique user per vault" do
    duplicate = Membership.new(
      user: @membership.user,
      vault: @membership.vault,
      role: :member
    )
    assert_not duplicate.valid?
  end

  test "should have role enum" do
    assert @membership.role_owner?
  end
end
