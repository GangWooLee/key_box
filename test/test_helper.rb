ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all
  end
end

module AuthenticationTestHelper
  def log_in_as(user, password: "password123")
    post login_path, params: { email: user.email, password: password }
  end

  def log_in_and_follow(user, password: "password123")
    log_in_as(user, password: password)
    follow_redirect!
  end
end

class ActionDispatch::IntegrationTest
  include AuthenticationTestHelper
end
