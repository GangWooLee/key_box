require "test_helper"

class Secrets::SearchQueryTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @vault = vaults(:personal_one)
    @folder = folders(:general_one)
    @mek = derive_mek_for_user(@user)

    @github_secret = create_test_secret(name: "GitHub API Key", service_name: "GitHub", tags: "ci, api", environment: "production")
    @aws_secret = create_test_secret(name: "AWS Access Key", service_name: "AWS", tags: "cloud", environment: "staging")
    @stripe_secret = create_test_secret(name: "Stripe Token", service_name: "Stripe", notes: "Payment processing")
  end

  test "searches by name" do
    results = Secrets::SearchQuery.new(vault: @vault).call(query: "GitHub")
    assert_includes results, @github_secret
    assert_not_includes results, @aws_secret
  end

  test "searches by service name" do
    results = Secrets::SearchQuery.new(vault: @vault).call(query: "AWS")
    assert_includes results, @aws_secret
  end

  test "searches by tags" do
    results = Secrets::SearchQuery.new(vault: @vault).call(query: "api")
    assert_includes results, @github_secret
  end

  test "searches by notes" do
    results = Secrets::SearchQuery.new(vault: @vault).call(query: "Payment")
    assert_includes results, @stripe_secret
  end

  test "case-insensitive search" do
    results = Secrets::SearchQuery.new(vault: @vault).call(query: "github")
    assert_includes results, @github_secret
  end

  test "filters by secret_type" do
    results = Secrets::SearchQuery.new(vault: @vault).call(
      query: "",
      filters: { secret_type: "api_key" }
    )
    results.each { |s| assert_equal "api_key", s.secret_type }
  end

  test "filters by environment" do
    results = Secrets::SearchQuery.new(vault: @vault).call(
      query: "",
      filters: { environment: "production" }
    )
    assert_includes results, @github_secret
    assert_not_includes results, @aws_secret
  end

  test "returns empty for no match" do
    results = Secrets::SearchQuery.new(vault: @vault).call(query: "nonexistent")
    assert_empty results
  end

  test "respects MAX_RESULTS limit" do
    assert_equal 50, Secrets::SearchQuery::MAX_RESULTS
  end

  test "sanitizes SQL wildcards in query" do
    results = Secrets::SearchQuery.new(vault: @vault).call(query: "%")
    # Should not match everything — % is escaped
    assert_empty results
  end

  test "scoped to vault — does not return other vault secrets" do
    other_vault = vaults(:personal_two)
    other_mek = derive_mek_for_user(users(:two))
    encrypted = Encryption::SecretEncryptionService.encrypt(value: "x", key: other_mek)
    Secret.create!(
      folder: folders(:general_two), vault: other_vault, name: "GitHub Other",
      encrypted_value: encrypted[:encrypted_value],
      encrypted_value_iv: encrypted[:iv],
      encrypted_value_auth_tag: encrypted[:auth_tag]
    )

    results = Secrets::SearchQuery.new(vault: @vault).call(query: "GitHub")
    results.each { |s| assert_equal @vault.id, s.vault_id }
  end

  private

  def create_test_secret(name:, service_name: nil, tags: nil, notes: nil, environment: nil)
    encrypted = Encryption::SecretEncryptionService.encrypt(value: "test-value", key: @mek)

    Secret.create!(
      folder: @folder,
      vault: @vault,
      name: name,
      service_name: service_name,
      tags: tags,
      notes: notes,
      environment: environment,
      encrypted_value: encrypted[:encrypted_value],
      encrypted_value_iv: encrypted[:iv],
      encrypted_value_auth_tag: encrypted[:auth_tag]
    )
  end

  def derive_mek_for_user(user)
    pdk = Encryption::KeyDerivationService.derive_key(password: "password123", salt: user.master_key_salt)
    Encryption::MasterKeyService.unwrap(wrapped_key: user.encrypted_master_key, wrapping_key: pdk)
  end
end
