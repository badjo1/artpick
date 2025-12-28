# Clear existing data (optional - uncomment if you want to reset)
# Vote.destroy_all
# Image.destroy_all
# VotingSession.destroy_all
# InviteLink.destroy_all
# User.destroy_all

puts "Creating admin user..."
User.create!(
  email_address: "admin@artpick.com",
  password: "password123",
  password_confirmation: "password123"
) unless User.exists?(email_address: "admin@artpick.com")

puts "Setting up application settings..."
Setting.set_value("voting_deadline", DateTime.new(2025, 1, 8, 23, 59, 59))
Setting.set_value("results_intro", "Bekijk de definitieve ranking van de 52 kunstwerken uit de tentoonstelling.")

puts "Creating invite links..."
3.times do |i|
  InviteLink.create!(
    name: "Campaign #{i + 1}",
    active: true
  )
end

puts "Seed data created successfully!"
puts ""
puts "==========================================="
puts "Admin Login Credentials:"
puts "Email: admin@artpick.com"
puts "Password: password123"
puts "==========================================="
puts ""
puts "Next steps:"
puts "1. Start the server: bin/rails server"
puts "2. Visit http://localhost:3000/admin to login"
puts "3. Upload 52 images via the admin panel"
puts "4. Test the voting flow at http://localhost:3000"
