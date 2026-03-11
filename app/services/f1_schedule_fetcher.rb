# frozen_string_literal: true

require "net/http"
require "nokogiri"

class F1ScheduleFetcher
  def initialize(url)
    @url = url
  end

  def call
    html = fetch_html
    return Result.failure("Failed to fetch page") if html.nil?

    parser = F1Schedule::EventParser.new
    events = parser.extract_events(html)
    timezone_offset = extract_timezone_offset(html)

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
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.open_timeout = 5
    http.read_timeout = 10

    request = Net::HTTP::Get.new(uri.request_uri)
    request["User-Agent"] = "Mozilla/5.0 (compatible; F1LocalTiming/1.0)"

    response = http.request(request)

    # Handle redirects (only to formula1.com)
    if response.is_a?(Net::HTTPRedirection)
      redirect_uri = URI.parse(response["location"])
      return nil unless redirect_uri.host&.match?(/\A(\w+\.)?formula1\.com\z/)
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
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.open_timeout = 5
    http.read_timeout = 10

    request = Net::HTTP::Get.new(uri.request_uri)
    request["User-Agent"] = "Mozilla/5.0 (compatible; F1LocalTiming/1.0)"

    response = http.request(request)
    return nil unless response.is_a?(Net::HTTPSuccess)

    response.body
  rescue StandardError
    nil
  end

  def extract_timezone_offset(html)
    if html =~ /(\d{1,2})\s*hours?\s*ahead\s*of\s*UTC/i
      hours = ::Regexp.last_match(1).to_i
      return format_offset(hours) if hours <= 14
    elsif html =~ /(\d{1,2})\s*hours?\s*behind\s*UTC/i
      hours = ::Regexp.last_match(1).to_i
      return format_offset(-hours) if hours <= 12
    end

    "+00:00"
  end

  def format_offset(hours)
    sign = hours >= 0 ? "+" : "-"
    "#{sign}#{hours.abs.to_s.rjust(2, '0')}:00"
  end
end
