

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end

FactoryBot.define do
  # regular good user (valid affil)
  factory :user do
    uid { 'jdoe' }
    first_name { 'John' }
    last_name  { 'Doe' }
    email { 'jdoe@columbia.edu' }
    barcode { '123456789' }
    affils { ['CUL_role-clio-REG'] }
  end

  # This will use the User class (Admin would have been guessed)
  factory :admin, class: User do
    uid { 'admin' }
    first_name { 'Admin' }
    last_name { 'User' }
    email { 'adminuser@example.com' }
  end
end
