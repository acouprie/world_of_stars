source "https://rubygems.org"

gem "rails", "~> 8.1.3"
# Modern asset pipeline
gem "propshaft"
# PostgreSQL adapter
gem "pg", "~> 1.1"
# Web server
gem "puma", ">= 5.0"
# Vite bundler for React + Pixi.js
gem "vite_rails"
# Hotwire — Turbo Stream server helpers
gem "turbo-rails"
# JSON builder for island endpoints
gem "jbuilder"
# Password hashing for rails generate authentication
gem "bcrypt", "~> 3.1.7"
# Redis — ActionCable, Sidekiq, cache
gem "redis", "~> 5.0"
# Background jobs (builds, fleets, faction ticks)
gem "sidekiq", "~> 7.0"
gem "connection_pool", "< 4.0"
# Rate limiting (login attempts, futures APIs)
gem "rack-attack"
# Translations for Rails built-in components (validations, time helpers, etc.)
gem "rails-i18n"
# Windows timezone support
gem "tzinfo-data", platforms: %i[windows jruby]
# Faster boot via caching
gem "bootsnap", require: false
# Container deployment
gem "kamal", require: false
# HTTP/2 + asset compression in front of Puma
gem "thruster", require: false
# Active Storage image variants
gem "image_processing", "~> 1.2"

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  # Test suite
  gem "rspec-rails", "~> 7.0"
  gem "factory_bot_rails"
  gem "webmock"          # blocks all external HTTP calls in tests
  gem "vcr"              # record/replay real HTTP calls for integration tests
  gem "faker"
end

group :test do
  gem "shoulda-matchers", "~> 6.0"
end

group :development do
  gem "web-console"
end
