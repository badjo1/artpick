ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

# Workaround for Rails 8.1.1 + Minitest 6.0.0 compatibility issue
module Rails
  module TestUnit
    class Runner
      def self.run(argv = [])
        Minitest.run(argv)
      end
    end
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    # parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

class ActionDispatch::IntegrationTest
  include SessionTestHelper

  def fixture_file_upload(path, mime_type)
    file_path = Rails.root.join("test", "fixtures", "files", path)
    Rack::Test::UploadedFile.new(file_path, mime_type)
  end
end
