# frozen_string_literal: true

require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.default_cassette_options = {
    serialize_with: :json
  }
  config.filter_sensitive_data('<GOOGLE_API_KEY>') { ENV.fetch('GOOGLE_API_KEY') }
  config.filter_sensitive_data('<STRIPE_SECRET_KEY>') { ENV.fetch('STRIPE_SECRET_KEY') }
  config.filter_sensitive_data('<STRIPE_PUBLISHABLE_KEY>') { ENV.fetch('STRIPE_PUBLISHABLE_KEY') }
end