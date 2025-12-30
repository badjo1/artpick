namespace :test do
  desc "Test all admin pages are working"
  task admin_pages: :environment do
    require 'net/http'
    require 'uri'

    puts "Testing Admin Pages..."
    puts "=" * 60

    # Create or find admin user
    admin = User.find_or_create_by!(email_address: "admin@artpick.com") do |u|
      u.password = "password"
      u.role = "admin"
    end

    # Test routes
    routes = [
      { path: '/admin', name: 'Dashboard' },
      { path: '/admin/exhibitions', name: 'Exhibitions' },
      { path: '/admin/artists', name: 'Artists' },
      { path: '/admin/spaces', name: 'Spaces' },
      { path: '/admin/analytics', name: 'Analytics' }
    ]

    # Create a test request context
    app = ActionDispatch::Integration::Session.new(Rails.application)

    # Sign in
    app.post '/session', params: {
      email_address: admin.email_address,
      password: 'password'
    }

    unless app.response.redirect?
      puts "✗ Failed to sign in"
      exit 1
    end

    puts "✓ Signed in as #{admin.email_address}"
    puts ""

    # Test each route
    results = routes.map do |route|
      begin
        app.get route[:path]
        status = app.response.status

        if status == 200
          puts "✓ #{route[:name].ljust(20)} - HTTP #{status}"
          true
        else
          puts "✗ #{route[:name].ljust(20)} - HTTP #{status}"
          if status == 500
            puts "  Error: #{app.response.body[0..200]}"
          end
          false
        end
      rescue => e
        puts "✗ #{route[:name].ljust(20)} - Error: #{e.message}"
        false
      end
    end

    puts ""
    puts "=" * 60
    passed = results.count(true)
    total = results.size
    puts "Results: #{passed}/#{total} pages working"

    if passed == total
      puts "✓ All admin pages are working!"
      exit 0
    else
      puts "✗ Some admin pages have errors"
      exit 1
    end
  end
end
