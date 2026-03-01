require "test_helper"

class FolderTest < ActiveSupport::TestCase
  setup do
    @folder = folders(:general_one)
  end

  test "should be valid" do
    assert @folder.valid?
  end

  test "should require name" do
    @folder.name = nil
    assert_not @folder.valid?
  end

  test "should enforce name length limit" do
    @folder.name = "a" * 101
    assert_not @folder.valid?
  end

  test "should enforce unique name per vault" do
    duplicate = Folder.new(
      vault: @folder.vault,
      name: @folder.name,
      position: 1
    )
    assert_not duplicate.valid?
  end

  test "should belong to vault" do
    assert_respond_to @folder, :vault
    assert_not_nil @folder.vault
  end

  test "should have many secrets" do
    assert_respond_to @folder, :secrets
  end

  test "ordered scope should sort by position" do
    vault = @folder.vault
    second = Folder.create!(vault: vault, name: "Second", position: 1)
    ordered = vault.folders.ordered
    assert_equal @folder, ordered.first
    assert_equal second, ordered.last
  end
end
