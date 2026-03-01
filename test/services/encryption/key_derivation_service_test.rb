require "test_helper"

class Encryption::KeyDerivationServiceTest < ActiveSupport::TestCase
  test "should generate random salt of correct length" do
    salt = Encryption::KeyDerivationService.generate_salt
    assert_equal 32, salt.bytesize
  end

  test "should generate unique salts" do
    salt1 = Encryption::KeyDerivationService.generate_salt
    salt2 = Encryption::KeyDerivationService.generate_salt
    assert_not_equal salt1, salt2
  end

  test "should derive key of correct length" do
    salt = Encryption::KeyDerivationService.generate_salt
    key = Encryption::KeyDerivationService.derive_key(password: "test_password", salt: salt)
    assert_equal 32, key.bytesize
  end

  test "should derive same key for same password and salt" do
    salt = Encryption::KeyDerivationService.generate_salt
    key1 = Encryption::KeyDerivationService.derive_key(password: "test_password", salt: salt)
    key2 = Encryption::KeyDerivationService.derive_key(password: "test_password", salt: salt)
    assert_equal key1, key2
  end

  test "should derive different keys for different passwords" do
    salt = Encryption::KeyDerivationService.generate_salt
    key1 = Encryption::KeyDerivationService.derive_key(password: "password1", salt: salt)
    key2 = Encryption::KeyDerivationService.derive_key(password: "password2", salt: salt)
    assert_not_equal key1, key2
  end

  test "should derive different keys for different salts" do
    salt1 = Encryption::KeyDerivationService.generate_salt
    salt2 = Encryption::KeyDerivationService.generate_salt
    key1 = Encryption::KeyDerivationService.derive_key(password: "test_password", salt: salt1)
    key2 = Encryption::KeyDerivationService.derive_key(password: "test_password", salt: salt2)
    assert_not_equal key1, key2
  end
end
