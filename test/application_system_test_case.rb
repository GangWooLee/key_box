require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1440, 900 ]

  private

  def sign_in_as(user, password: "password123")
    visit login_path
    fill_in "Email address", with: user.email
    fill_in "Password", with: password
    click_button "Log in"
    assert_text "KeyBox", wait: 5
  end
end
