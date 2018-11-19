

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end


FactoryBot.define do
  factory :user do
    uid { "jdoe" }
    first_name { "John" }
    last_name  { "Doe" }
    email { "johndoe@example.com" }
    barcode { "123456789" }
  end

  # This will use the User class (Admin would have been guessed)
  factory :admin, class: User do
    uid { "admin" }
    first_name { "Admin" }
    last_name { "User" }
    email { "adminuser@example.com" }
  end
end
