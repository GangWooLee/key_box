require "test_helper"

class Encryption::SecretEncryptionServiceTest < ActiveSupport::TestCase
  setup do
    @key = OpenSSL::Random.random_bytes(32)
    @plaintext = "sk-proj-abc123def456ghi789"
  end

  test "should encrypt and decrypt successfully" do
    result = Encryption::SecretEncryptionService.encrypt(value: @plaintext, key: @key)

    decrypted = Encryption::SecretEncryptionService.decrypt(
      encrypted_value: result[:encrypted_value],
      iv: result[:iv],
      auth_tag: result[:auth_tag],
      key: @key
    )

    assert_equal @plaintext, decrypted
  end

  test "should produce different ciphertext each time" do
    result1 = Encryption::SecretEncryptionService.encrypt(value: @plaintext, key: @key)
    result2 = Encryption::SecretEncryptionService.encrypt(value: @plaintext, key: @key)

    assert_not_equal result1[:encrypted_value], result2[:encrypted_value]
    assert_not_equal result1[:iv], result2[:iv]
  end

  test "should return nil for wrong key" do
    result = Encryption::SecretEncryptionService.encrypt(value: @plaintext, key: @key)
    wrong_key = OpenSSL::Random.random_bytes(32)

    decrypted = Encryption::SecretEncryptionService.decrypt(
      encrypted_value: result[:encrypted_value],
      iv: result[:iv],
      auth_tag: result[:auth_tag],
      key: wrong_key
    )

    assert_nil decrypted
  end

  test "should return nil for tampered ciphertext" do
    result = Encryption::SecretEncryptionService.encrypt(value: @plaintext, key: @key)
    tampered = result[:encrypted_value].dup
    tampered[-1] = (tampered[-1].ord ^ 0xFF).chr

    decrypted = Encryption::SecretEncryptionService.decrypt(
      encrypted_value: tampered,
      iv: result[:iv],
      auth_tag: result[:auth_tag],
      key: @key
    )

    assert_nil decrypted
  end

  test "should handle empty string" do
    result = Encryption::SecretEncryptionService.encrypt(value: "", key: @key)

    decrypted = Encryption::SecretEncryptionService.decrypt(
      encrypted_value: result[:encrypted_value],
      iv: result[:iv],
      auth_tag: result[:auth_tag],
      key: @key
    )

    assert_equal "", decrypted
  end

  test "should handle long values" do
    long_value = "a" * 10_000
    result = Encryption::SecretEncryptionService.encrypt(value: long_value, key: @key)

    decrypted = Encryption::SecretEncryptionService.decrypt(
      encrypted_value: result[:encrypted_value],
      iv: result[:iv],
      auth_tag: result[:auth_tag],
      key: @key
    )

    assert_equal long_value, decrypted
  end
end
