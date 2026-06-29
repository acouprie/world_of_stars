module SystemHelpers
  # Login via the home page form (login tab is visible by default).
  # Factory users have password "Password1!" by default.
  def sign_in_as(user, password: "Password1!")
    visit root_path
    within("[data-auth-target='loginForm']") do
      fill_in "email_address", with: user.email_address
      fill_in "password",      with: password
      click_button "Se connecter"
    end
    # Wait for the post-login redirect to complete. Turbo form submissions can
    # settle the DOM before the navigation finishes; this assertion ensures the
    # login page is gone before the caller proceeds.
    expect(page).not_to have_selector("[data-auth-target='loginForm']")
  end
end

RSpec.configure do |config|
  config.include SystemHelpers, type: :system
end
