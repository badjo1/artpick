#!/usr/bin/env ruby
# Test script to verify admin infrastructure is complete

require_relative 'config/environment'

puts "Testing Admin Infrastructure..."
puts "=" * 60

# Test 1: Check all controllers exist
puts "\n1. Checking Controllers..."
controllers = [
  ['Admin::DashboardController', 'index'],
  ['Admin::ExhibitionsController', 'index'],
  ['Admin::ArtistsController', 'index'],
  ['Admin::SpacesController', 'index'],
  ['Admin::AnalyticsController', 'index']
]

controller_results = controllers.map do |class_name, action|
  begin
    klass = class_name.constantize
    if klass.instance_methods.include?(action.to_sym)
      puts "✓ #{class_name}##{action}"
      true
    else
      puts "✗ #{class_name}##{action} - method missing"
      false
    end
  rescue NameError
    puts "✗ #{class_name} - controller missing"
    false
  end
end

# Test 2: Check all views exist
puts "\n2. Checking Views..."
views = [
  'app/views/admin/dashboard/index.html.erb',
  'app/views/admin/exhibitions/index.html.erb',
  'app/views/admin/artists/index.html.erb',
  'app/views/admin/spaces/index.html.erb',
  'app/views/admin/analytics/index.html.erb'
]

view_results = views.map do |path|
  if File.exist?(path)
    puts "✓ #{path}"
    true
  else
    puts "✗ #{path} - file missing"
    false
  end
end

# Test 3: Check routes exist
puts "\n3. Checking Routes..."
routes_to_check = [
  [:admin_root, '/admin'],
  [:admin_exhibitions, '/admin/exhibitions'],
  [:admin_artists, '/admin/artists'],
  [:admin_spaces, '/admin/spaces'],
  [:admin_analytics, '/admin/analytics']
]

route_results = routes_to_check.map do |name, path|
  begin
    if Rails.application.routes.url_helpers.respond_to?(name.to_s + '_path')
      actual_path = Rails.application.routes.url_helpers.send(name.to_s + '_path')
      puts "✓ #{name}_path -> #{actual_path}"
      true
    else
      puts "✗ #{name}_path - route helper missing"
      false
    end
  rescue => e
    puts "✗ #{name}_path - error: #{e.message}"
    false
  end
end

# Summary
puts "\n" + "=" * 60
total_tests = controller_results.size + view_results.size + route_results.size
passed_tests = [controller_results, view_results, route_results].flatten.count(true)

puts "Results: #{passed_tests}/#{total_tests} checks passed"

if passed_tests == total_tests
  puts "✓ All admin infrastructure is in place!"
  puts "\nℹ️  To test pages work in browser:"
  puts "   1. Start server: bin/rails s"
  puts "   2. Login as admin: admin@artpick.com / password"
  puts "   3. Visit: http://localhost:3000/admin"
  exit 0
else
  puts "✗ Some infrastructure is missing"
  exit 1
end
