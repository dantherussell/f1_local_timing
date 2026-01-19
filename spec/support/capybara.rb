require "capybara/rspec"

Capybara.default_max_wait_time = 5

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 900 ]
  end
end
