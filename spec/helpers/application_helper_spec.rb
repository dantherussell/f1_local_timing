require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#dark_theme?" do
    context "when theme cookie is dark" do
      before { helper.request.cookies[:theme] = "dark" }

      it "returns true" do
        expect(helper.dark_theme?).to be true
      end
    end

    context "when theme cookie is light" do
      before { helper.request.cookies[:theme] = "light" }

      it "returns false" do
        expect(helper.dark_theme?).to be false
      end
    end

    context "when theme cookie is not set" do
      it "returns false" do
        expect(helper.dark_theme?).to be false
      end
    end
  end

  describe "#theme_logo_image" do
    context "when dark theme" do
      before { helper.request.cookies[:theme] = "dark" }

      it "returns dark logo image tag" do
        expect(helper.theme_logo_image).to match(/f1_furs_dark/)
      end
    end

    context "when light theme" do
      before { helper.request.cookies[:theme] = "light" }

      it "returns light logo image tag" do
        expect(helper.theme_logo_image).to match(/f1_furs_light/)
      end
    end
  end

  describe "#theme_toggle_link" do
    context "when dark theme" do
      before { helper.request.cookies[:theme] = "dark" }

      it "returns link to light mode" do
        expect(helper.theme_toggle_link).to include("Light Mode")
        expect(helper.theme_toggle_link).to include("theme=light")
      end
    end

    context "when light theme" do
      before { helper.request.cookies[:theme] = "light" }

      it "returns link to dark mode" do
        expect(helper.theme_toggle_link).to include("Dark Mode")
        expect(helper.theme_toggle_link).to include("theme=dark")
      end
    end
  end

  describe "#print_view?" do
    context "when path includes print" do
      before { allow(helper.request).to receive(:path).and_return("/seasons/1/weekends/1/print") }

      it "returns true" do
        expect(helper.print_view?).to be true
      end
    end

    context "when path does not include print" do
      before { allow(helper.request).to receive(:path).and_return("/seasons/1/weekends/1") }

      it "returns false" do
        expect(helper.print_view?).to be false
      end
    end
  end
end
