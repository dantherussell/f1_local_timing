# frozen_string_literal: true

require "net/http"
require "nokogiri"

class F1ScheduleFetcher
  # Series to exclude (exact matches only, not partial)
  EXCLUDED_SERIES = [
    "Paddock Club",
    "FIA",  # Standalone FIA entries (not "FIA Formula 2", etc.)
    "Promoter Activity",
    "F1 Experiences"
  ].freeze

  EXCLUDED_PATTERNS = /Hot Laps|Parade|Anthem|Press Conference|Pit Stop|Presentation|Demonstration|Tribute|Fly Past/i

  def initialize(url)
    @url = url
  end

  def call
    html = fetch_html
    return Result.failure("Failed to fetch page") if html.nil?

    doc = Nokogiri::HTML(html)
    timezone_offset = extract_timezone_offset(doc, html)
    events = extract_events(doc, html)

    Result.success(
      timezone_offset: timezone_offset,
      events: events
    )
  rescue StandardError => e
    Result.failure("Error parsing schedule: #{e.message}")
  end

  private

  def fetch_html
    uri = URI.parse(@url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE # F1.com has CRL verification issues

    request = Net::HTTP::Get.new(uri.request_uri)
    request["User-Agent"] = "Mozilla/5.0 (compatible; F1LocalTiming/1.0)"

    response = http.request(request)

    # Handle redirects
    if response.is_a?(Net::HTTPRedirection)
      return fetch_html_from_url(response["location"])
    end

    return nil unless response.is_a?(Net::HTTPSuccess)

    response.body
  rescue StandardError
    nil
  end

  def fetch_html_from_url(url)
    uri = URI.parse(url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri)
    request["User-Agent"] = "Mozilla/5.0 (compatible; F1LocalTiming/1.0)"

    response = http.request(request)
    return nil unless response.is_a?(Net::HTTPSuccess)

    response.body
  rescue StandardError
    nil
  end

  def extract_timezone_offset(doc, html)
    # Look for pattern like "X hours ahead of UTC" or "X hours behind UTC"
    if html =~ /(\d+)\s*hours?\s*ahead\s*of\s*UTC/i
      hours = ::Regexp.last_match(1).to_i
      format_offset(hours)
    elsif html =~ /(\d+)\s*hours?\s*behind\s*UTC/i
      hours = ::Regexp.last_match(1).to_i
      format_offset(-hours)
    else
      "+00:00"
    end
  end

  def format_offset(hours)
    sign = hours >= 0 ? "+" : "-"
    "#{sign}#{hours.abs.to_s.rjust(2, '0')}:00"
  end

  def extract_events(doc, html)
    events = []
    text_content = doc.text

    # Extract year from page content
    year = text_content.match(/\b(20\d{2})\b/)&.captures&.first&.to_i || Date.current.year

    # Split content by day headers
    day_pattern = /(MONDAY|TUESDAY|WEDNESDAY|THURSDAY|FRIDAY|SATURDAY|SUNDAY)\s+(\d{1,2})\s+(JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)/i

    # Find all day sections - only use the first occurrence of each day
    day_matches = text_content.to_enum(:scan, day_pattern).map { Regexp.last_match }
    seen_days = Set.new
    unique_day_matches = day_matches.select do |match|
      day_key = "#{match[2]}-#{match[3]}"
      if seen_days.include?(day_key)
        false
      else
        seen_days.add(day_key)
        true
      end
    end

    unique_day_matches.each_with_index do |day_match, idx|
      day_num = day_match[2].to_i
      month_name = day_match[3]
      month = Date::MONTHNAMES.index(month_name.capitalize)
      current_date = Date.new(year, month, day_num)

      # Get the text section for this day (until next day or end)
      start_pos = day_match.end(0)
      end_pos = unique_day_matches[idx + 1]&.begin(0) || text_content.length
      day_content = text_content[start_pos...end_pos]

      # Extract events from this day's content
      extract_events_from_day(day_content, current_date, events)
    end

    # Deduplicate events by date+series+session (keep first occurrence)
    events.uniq { |e| [ e[:date], e[:series], e[:session] ] }
  end

  def extract_events_from_day(content, date, events)
    # Pattern: [Series Name][Session Name][HH:MM - HH:MM]
    # The time pattern helps us identify event boundaries
    time_pattern = /(\d{2}):(\d{2})\s*-\s*\d{2}:\d{2}/

    # Find all times in the content
    time_matches = content.to_enum(:scan, time_pattern).map { Regexp.last_match }

    time_matches.each_with_index do |time_match, idx|
      start_hour = time_match[1].to_i
      start_min = time_match[2].to_i
      local_time = format("%02d:%02d", start_hour, start_min)

      # Get the text before this time (which contains series and session)
      # Look back from the time to the previous time (or start of content)
      # Use match.end(0) to get the exact position, not String#index which finds first occurrence
      start_pos = idx.zero? ? 0 : time_matches[idx - 1].end(0)
      end_pos = time_match.begin(0)
      prefix_text = content[start_pos...end_pos]

      series, session = parse_series_and_session(prefix_text)

      # Skip if parsing failed (JSON/HTML garbage)
      next if series.nil? && session.nil?
      next if excluded?(series, session)

      events << {
        date: date,
        local_time: local_time,
        series: normalize_series_name(series),
        session: normalize_session_name(session, series)
      }
    end
  end

  def parse_series_and_session(text)
    # Skip if it contains JSON/HTML artifacts
    return [ nil, nil ] if text.include?("className") || text.include?('":"')

    # Normalize all whitespace (including non-breaking spaces) to single regular spaces
    text = text.gsub(/[[:space:]]+/, " ")
    text = text.gsub(/Local time/i, "").strip
    return [ nil, nil ] if text.empty?

    # Session patterns - must match the START of session names
    # Order matters: more specific patterns first
    session_patterns = [
      /FIRST PRACTICE/i,
      /SECOND PRACTICE/i,
      /THIRD PRACTICE/i,
      /FREE PRACTICE/i,
      /PRACTICE SESSION/i,
      /PRACTICE/i,
      /SPRINT QUALIFYING/i,
      /SPRINT RACE/i,
      /SPRINT SHOOTOUT/i,
      /SPRINT(?!\s*Challenge)/i,
      /QUALIFYING SESSION/i,
      /QUALIFYING/i,
      /FEATURE RACE/i,
      /FIRST RACE/i,
      /SECOND RACE/i,
      /THIRD RACE/i,
      /FOURTH RACE/i,
      /GRAND PRIX/i,
      /RACE/i,
      /Team Pit Stop/i,
      /Pit Lane Walk/i,
      /Track Tour/i,
      /Presentation/i,
      /Parade/i,
      /Anthem/i,
      /Press Conference/i,
      /Hot Laps/i
    ]

    match = nil
    session_patterns.each do |pattern|
      match = text.match(pattern)
      break if match
    end

    if match
      series = text[0...match.begin(0)].strip
      session = text[match.begin(0)..].strip
    else
      series = text.strip
      session = nil
    end

    series = nil if series.empty?
    [ series, session ]
  end

  def excluded?(series, session)
    # Check if series starts with an excluded name (handles "Paddock ClubPaddock Club..." cases)
    # But don't exclude "FIA Formula 2" just because it contains "FIA"
    EXCLUDED_SERIES.each do |excluded|
      next if excluded == "FIA" && series&.match?(/FIA\s*Formula/i)
      return true if series&.start_with?(excluded)
    end
    # Check patterns against both series and session
    return true if series&.match?(EXCLUDED_PATTERNS)
    return true if session&.match?(EXCLUDED_PATTERNS)

    false
  end

  def normalize_series_name(series)
    return "Formula 1" if series.nil? || series == "Unknown"

    # Normalize "FORMULA" to "Formula" (keep the number as-is)
    series.strip.gsub(/FORMULA/i, "Formula")
  end

  def normalize_session_name(session, series)
    return "Unknown" if session.nil? || session.empty?

    name = session.dup

    # Remove anything in brackets (lap counts, durations, etc.)
    name = name.gsub(/\s*\([^)]*\)/, "")

    # Remove "Session" wherever it appears
    name = name.gsub(/\s*Session\b/i, "")

    # Convert ALL CAPS to proper case
    name = name.split.map(&:capitalize).join(" ") if name == name.upcase

    # Normalize F1 practice session names
    if series =~ /Formula\s*1/i || series.nil?
      name = case name
      when /First\s*Practice|Practice\s*1|FP\s*1/i then "Free Practice 1"
      when /Second\s*Practice|Practice\s*2|FP\s*2/i then "Free Practice 2"
      when /Third\s*Practice|Practice\s*3|FP\s*3/i then "Free Practice 3"
      when /Sprint\s*Qualifying/i then "Sprint Qualifying"
      when /Sprint\s*Race|^Sprint$/i then "Sprint"
      when /^Qualifying$/i then "Qualifying"
      when /^Race$/i then "Race"
      else name
      end
    end

    name.strip
  end
end
