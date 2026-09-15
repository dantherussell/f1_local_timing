# frozen_string_literal: true

require "net/http"

class TelegramNotifier
  API_HOST = "api.telegram.org"

  def initialize(image:, caption:)
    @image = image
    @caption = caption
  end

  def call
    post_photo
    Result.success
  rescue StandardError => e
    Rails.logger.error("Telegram request failed (#{e.class})")
    Result.failure("Error sending Telegram message.")
  end

  private

  def post_photo
    uri = URI.parse("https://#{API_HOST}/bot#{ENV['TELEGRAM_BOT_TOKEN']}/sendPhoto")
    boundary = SecureRandom.hex(16)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.open_timeout = 5
    http.read_timeout = 15

    request = Net::HTTP::Post.new(uri.request_uri)
    request["User-Agent"] = "Mozilla/5.0 (compatible; F1LocalTiming/1.0)"
    request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
    request.body = multipart_body(boundary)

    response = http.request(request)
    return response if response.is_a?(Net::HTTPSuccess)

    raise "Telegram API error (#{response.code}): #{response.body}"
  end

  def multipart_body(boundary)
    parts = [
      form_field(boundary, "chat_id", ENV["TELEGRAM_CHAT_ID"]),
      form_field(boundary, "caption", @caption),
      form_file(boundary, "photo", @image, "schedule.png", "image/png")
    ]
    "#{parts.join}--#{boundary}--\r\n"
  end

  def form_field(boundary, name, value)
    "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"#{name}\"\r\n\r\n" \
      "#{value}\r\n"
  end

  def form_file(boundary, name, io, filename, content_type)
    "--#{boundary}\r\n" \
      "Content-Disposition: form-data; name=\"#{name}\"; filename=\"#{filename}\"\r\n" \
      "Content-Type: #{content_type}\r\n\r\n" \
      "#{io.read}\r\n"
  end
end
