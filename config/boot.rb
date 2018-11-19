ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

# Oracle gem prints warning unless this is in the environment
ENV['NLS_LANG'] = 'AMERICAN_AMERICA.US7ASCII'

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
