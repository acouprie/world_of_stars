require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Never record real Anthropic calls — filter the API key from cassettes
  config.filter_sensitive_data("<ANTHROPIC_API_KEY>") { ENV["ANTHROPIC_API_KEY"] }
  config.filter_sensitive_data("<LANGFUSE_SECRET_KEY>") { ENV["LANGFUSE_SECRET_KEY"] }

  config.default_cassette_options = {
    record: :none,
    allow_unused_http_interactions: false
  }
end
