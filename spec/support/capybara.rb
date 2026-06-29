require "capybara/rspec"
require "capybara/cuprite"

Capybara.javascript_driver = :cuprite
Capybara.default_driver    = :rack_test

PLAYWRIGHT_CHROME = File.expand_path("~/.cache/ms-playwright/chromium-1223/chrome-linux64/chrome")
ENV["BROWSER_PATH"] = PLAYWRIGHT_CHROME if File.exist?(PLAYWRIGHT_CHROME)

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size:     [1280, 800],
    browser_options: {
      "no-sandbox":             nil, # required: no kernel namespace isolation in Docker
      "disable-dev-shm-usage": nil, # required: Docker limits /dev/shm to 64MB by default
      "disable-gpu":            nil  # required: no GPU in headless Docker environments
    },
    process_timeout: 30,
    inspector:       false,
    headless:        true
  )
end

Capybara.default_max_wait_time = 5

RSpec.configure do |config|
  config.before(:each, type: :system) do |example|
    driven_by(example.metadata[:js] ? :cuprite : :rack_test)
  end
end
