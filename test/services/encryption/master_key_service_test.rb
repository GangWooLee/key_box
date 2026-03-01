require "test_helper"

class Encryption::MasterKeyServiceTest < ActiveSupport::TestCase
  setup do
    @mek = Encryption::MasterKeyService.generate_master_key
    @wrapping_key = OpenSSL::Random.random_bytes(32)
  end

  test "should generate master key of correct length" do
    assert_equal 32, @mek.bytesize
  end

  test "should generate unique master keys" do
    mek2 = Encryption::MasterKeyService.generate_master_key
    assert_not_equal @mek, mek2
  end

  test "should wrap and unwrap master key" do
    wrapped = Encryption::MasterKeyService.wrap(master_key: @mek, wrapping_key: @wrapping_key)
    unwrapped = Encryption::MasterKeyService.unwrap(wrapped_key: wrapped, wrapping_key: @wrapping_key)
    assert_equal @mek, unwrapped
  end

  test "should produce different wrapped output each time" do
    wrapped1 = Encryption::MasterKeyService.wrap(master_key: @mek, wrapping_key: @wrapping_key)
    wrapped2 = Encryption::MasterKeyService.wrap(master_key: @mek, wrapping_key: @wrapping_key)
    assert_not_equal wrapped1, wrapped2
  end

  test "should return nil for wrong wrapping key" do
    wrapped = Encryption::MasterKeyService.wrap(master_key: @mek, wrapping_key: @wrapping_key)
    wrong_key = OpenSSL::Random.random_bytes(32)
    result = Encryption::MasterKeyService.unwrap(wrapped_key: wrapped, wrapping_key: wrong_key)
    assert_nil result
  end

  test "should return nil for tampered wrapped key" do
    wrapped = Encryption::MasterKeyService.wrap(master_key: @mek, wrapping_key: @wrapping_key)
    tampered = wrapped.dup
    tampered[-1] = (tampered[-1].ord ^ 0xFF).chr
    result = Encryption::MasterKeyService.unwrap(wrapped_key: tampered, wrapping_key: @wrapping_key)
    assert_nil result
  end
end
