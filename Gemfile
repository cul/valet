source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 4'

# Use sqlite3 as the database for Active Record
gem 'sqlite3'

# Use SCSS for stylesheets
gem 'sass-rails'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier'

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails'

# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'

# # Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
# gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'

# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Testing
  gem 'rspec-rails'

end

group :development do
  # Let's use better_errors instead of this
  # # Access an IRB console on exception pages or by using <%= console %> in views
  # gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'

  # Better error page for Rack apps
  gem "better_errors"
  # And get a REPL
  gem 'binding_of_caller'

  # Deployment with Capistrano
  gem 'capistrano', '~> 3.0', require: false
  # Rails and Bundler integrations were moved out from Capistrano 3
  gem 'capistrano-rails', require: false
  gem 'capistrano-bundler', require: false
  # "idiomatic support for your preferred ruby version manager"
  gem 'capistrano-rvm', require: false
  # The `deploy:restart` hook for passenger applications is now in a separate gem
  # Just add it to your Gemfile and require it in your Capfile.
  gem 'capistrano-passenger', require: false

end

# # Authentication
gem 'devise', '~> 3.0'
gem 'cul_omniauth'

# Fetch ldap details - first name, last name, etc.
gem 'net-ldap'

# Talk to Voyager's Oracle DB, to e.g. fetch patron barcodes
gem 'ruby-oci8'

# Talk to our source for catalog records, a Solr search index
gem 'rsolr'

# Parse the MARC data structure of our catalog records
gem 'marc'

# Use Twitter Bootstrap for styling
gem 'bootstrap-sass'

# Talk to SCSB REST API
# gem 'rest-client'
gem 'faraday'

# Use MySQL for deployed server environments
gem 'mysql2'

# Talk to SCSB ActiveMQ via STOMP
gem 'stomp'

# DataTables
gem 'jquery-datatables-rails'



