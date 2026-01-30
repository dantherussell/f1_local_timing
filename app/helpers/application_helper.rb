module ApplicationHelper
  def dark_theme?
    cookies[:theme] == "dark"
  end

  def theme_logo_image
    image_name = dark_theme? ? "f1_furs_dark.png" : "f1_furs_light.png"
    image_tag image_name, size: "424x56", alt: ""
  end

  def theme_toggle_link
    if dark_theme?
      link_to "Light Mode", root_path(theme: "light"), data: { turbo_prefetch: false }
    else
      link_to "Dark Mode", root_path(theme: "dark"), data: { turbo_prefetch: false }
    end
  end

  def print_view?
    request.path.include?("print")
  end
end
