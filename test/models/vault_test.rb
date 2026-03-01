require "test_helper"

class VaultTest < ActiveSupport::TestCase
  setup do
    @vault = vaults(:personal_one)
  end

  # ===== Validations =====
  test "should be valid with valid attributes" do
    assert @vault.valid?
  end

  test "should require name" do
    @vault.name = nil
    assert_not @vault.valid?
  end

  test "should enforce name length limit" do
    @vault.name = "a" * 101
    assert_not @vault.valid?
  end

  test "should enforce description length limit" do
    @vault.description = "a" * 501
    assert_not @vault.valid?
  end

  # ===== Enums =====
  test "should have vault_type enum" do
    assert @vault.vault_type_personal?
    @vault.vault_type = :team
    assert @vault.vault_type_team?
  end

  # ===== Associations =====
  test "should have many memberships" do
    assert_respond_to @vault, :memberships
  end

  test "should have many folders" do
    assert_respond_to @vault, :folders
  end

  test "should have many secrets" do
    assert_respond_to @vault, :secrets
  end

  # ===== Instance Methods =====
  test "should return owner" do
    owner = @vault.owner
    assert_not_nil owner
    assert_equal users(:one), owner
  end
end
