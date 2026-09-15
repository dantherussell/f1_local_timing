require "rails_helper"

RSpec.describe "Telegram share", type: :system do
  let(:season) { create(:season) }
  let(:weekend) { create(:weekend, :monaco, season: season) }

  def visit_as_authed(path)
    visit "/test_auth"
    visit path
  end

  before do
    visit_as_authed telegram_season_weekend_path(season, weekend)
  end

  it "enables the submit button once the schedule image has been captured" do
    expect(page).to have_button("Send to Telegram", disabled: false)
  end

  it "posts to Telegram and redirects to the weekend page on success" do
    allow_any_instance_of(TelegramNotifier).to receive(:call).and_return(Result.success)

    fill_in "Preamble", with: "Race weekend is here!"
    click_on "Send to Telegram"

    expect(page).to have_current_path(season_weekend_path(season, weekend))
  end

  it "shows the error and re-enables the button when Telegram rejects the message" do
    allow_any_instance_of(TelegramNotifier).to receive(:call).and_return(Result.failure("Telegram is down"))

    fill_in "Preamble", with: "Race weekend is here!"
    click_on "Send to Telegram"

    expect(page).to have_content("Telegram is down")
    expect(page).to have_button("Send to Telegram", disabled: false)
  end
end
