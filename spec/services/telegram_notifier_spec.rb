# frozen_string_literal: true

require "rails_helper"

RSpec.describe TelegramNotifier do
  let(:image) { StringIO.new("fake png bytes") }
  let(:caption) { "Race weekend is here!" }
  let(:token) { "test-token" }
  let(:chat_id) { "-1001114923241" }
  let(:api_url) { "https://api.telegram.org/bot#{token}/sendPhoto" }

  before do
    @orig_token = ENV["TELEGRAM_BOT_TOKEN"]
    @orig_chat_id = ENV["TELEGRAM_CHAT_ID"]
    ENV["TELEGRAM_BOT_TOKEN"] = token
    ENV["TELEGRAM_CHAT_ID"] = chat_id
  end

  after do
    ENV["TELEGRAM_BOT_TOKEN"] = @orig_token
    ENV["TELEGRAM_CHAT_ID"] = @orig_chat_id
  end

  describe "#call" do
    subject(:result) { described_class.new(image: image, caption: caption).call }

    context "when Telegram accepts the photo" do
      before do
        stub_request(:post, api_url).to_return(status: 200, body: '{"ok":true}')
      end

      it "returns a successful result" do
        expect(result).to be_success
      end

      it "sends the chat_id and caption as form fields" do
        result
        expect(WebMock).to have_requested(:post, api_url)
          .with { |req| req.body.include?(chat_id) && req.body.include?(caption) }
      end

      it "sends the image as a multipart photo field" do
        result
        expect(WebMock).to have_requested(:post, api_url)
          .with { |req| req.body.include?('name="photo"') && req.body.include?("fake png bytes") }
      end
    end

    context "when Telegram rejects the request" do
      before do
        stub_request(:post, api_url).to_return(status: 400, body: '{"ok":false,"description":"Bad Request"}')
      end

      it "returns a failure result" do
        expect(result).to be_failure
      end

      it "returns a generic error message, not the raw response body" do
        expect(result.errors.join).not_to include("Bad Request")
        expect(result.errors.join).to include("Error sending Telegram message")
      end

      it "logs the failure server-side for debugging" do
        expect(Rails.logger).to receive(:error).with(a_string_including("Telegram"))
        result
      end
    end

    context "when there is a network error" do
      before do
        stub_request(:post, api_url).to_timeout
      end

      it "returns a failure result" do
        expect(result).to be_failure
      end
    end

    context "when the bot token is malformed and breaks URI parsing" do
      let(:token) { "bad token with spaces" }

      it "returns a failure result" do
        expect(result).to be_failure
      end

      it "does not leak the token in the error message" do
        expect(result.errors.join).not_to include(token)
      end
    end
  end
end
