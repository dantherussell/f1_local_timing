require "rails_helper"

RSpec.describe "Weekend time views", type: :system do
  let(:season) { create(:season) }
  let(:weekend) { create(:weekend, season: season, local_time_offset: "-08:00") }
  let(:session) { create(:session) }

  before do
    # Create events across multiple days
    day1 = weekend.days.find_by(date: weekend.first_day)
    day2 = weekend.days.find_by(date: weekend.last_day)

    # UTC 02:00 on first day = 18:00 previous day in track time (UTC-8)
    create(:event, day: day1, session: session, start_time: Time.parse("02:00"))
    # UTC 06:00 on last day = 22:00 previous day in track time (UTC-8)
    create(:event, day: day2, session: session, start_time: Time.parse("06:00"))
  end

  describe "time toggle buttons" do
    it "shows local times by default for unauthenticated users" do
      visit season_weekend_path(season, weekend)

      expect(page).to have_css("#local_times", visible: true)
      expect(page).to have_css("#track_times", visible: false)
      expect(page).not_to have_css("#utc_times")
    end

    it "switches to track times when clicked" do
      visit season_weekend_path(season, weekend)

      click_on "Track Times"

      expect(page).to have_css("#local_times", visible: false)
      expect(page).to have_css("#track_times", visible: true)
    end

    it "switches back to local times when clicked" do
      visit season_weekend_path(season, weekend)

      click_on "Track Times"
      click_on "Local Times"

      expect(page).to have_css("#local_times", visible: true)
      expect(page).to have_css("#track_times", visible: false)
    end
  end

  describe "track times view" do
    it "displays times converted to track timezone" do
      visit season_weekend_path(season, weekend)
      click_on "Track Times"

      # UTC 02:00 - 8 hours = 18:00 track time
      expect(page).to have_content("18:00")
      # UTC 06:00 - 8 hours = 22:00 track time
      expect(page).to have_content("22:00")
    end

    it "groups events by track date" do
      visit season_weekend_path(season, weekend)
      click_on "Track Times"

      # Events should be grouped by track-local dates (one day earlier due to UTC-8)
      track_view = find("#track_times")
      day_headers = track_view.all(".day-header h4").map(&:text)

      # Should show dates one day earlier than the stored UTC dates
      expect(day_headers.length).to eq(2)
    end
  end

  describe "local times view" do
    it "groups events by user local date via JavaScript" do
      visit season_weekend_path(season, weekend)

      # Wait for JavaScript to process
      expect(page).to have_css("#local_times .day-header")

      local_view = find("#local_times")
      day_headers = local_view.all(".day-header").map { |h| h.find("h4").text }

      # Should have day headers inserted by JavaScript
      expect(day_headers).not_to be_empty
    end

    it "displays times using local_time gem" do
      visit season_weekend_path(season, weekend)

      # The local_time gem converts times client-side
      # We just verify the structure exists
      expect(page).to have_css("#local_times table tbody tr")
    end
  end

  describe "authenticated user" do
    def visit_as_authed(path)
      visit path
      page.driver.browser.manage.add_cookie(name: "authed", value: "true")
      visit path
    end

    it "shows UTC times view by default" do
      visit_as_authed season_weekend_path(season, weekend)

      expect(page).to have_css("#utc_times", visible: true)
      expect(page).to have_css("#local_times", visible: false)
      expect(page).to have_css("#track_times", visible: false)
    end

    it "shows UTC button" do
      visit_as_authed season_weekend_path(season, weekend)

      expect(page).to have_link("UTC Times")
    end

    it "displays raw UTC times in UTC view" do
      visit_as_authed season_weekend_path(season, weekend)

      # Should show the raw UTC times
      expect(page).to have_content("02:00")
      expect(page).to have_content("06:00")
    end

    it "shows admin links in UTC view" do
      visit_as_authed season_weekend_path(season, weekend)

      expect(page).to have_link("Add Event")
      expect(page).to have_link("Edit Day")
      expect(page).to have_link("Delete Day")
    end

    it "can switch between all three views" do
      visit_as_authed season_weekend_path(season, weekend)

      click_on "Local Times"
      expect(page).to have_css("#local_times", visible: true)

      click_on "Track Times"
      expect(page).to have_css("#track_times", visible: true)

      click_on "UTC Times"
      expect(page).to have_css("#utc_times", visible: true)
    end
  end
end
