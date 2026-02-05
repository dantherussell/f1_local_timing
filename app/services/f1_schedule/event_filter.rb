# frozen_string_literal: true

module F1Schedule
  # Determines which events should be excluded from import
  # Consolidates all exclusion rules in one place
  class EventFilter
    # Series that are always excluded (exact prefix match)
    EXCLUDED_SERIES = [
      "Paddock Club",
      "Promoter Activity",
      "F1 Experiences"
    ].freeze

    # Patterns that exclude events (matched against series OR session)
    EXCLUDED_PATTERNS = [
      /Hot Laps/i,
      /Parade/i,
      /Anthem/i,
      /Press Conference/i,
      /Pit Stop/i,
      /Presentation/i,
      /Demonstration/i,
      /Tribute/i,
      /Fly Past/i
    ].freeze

    def excluded?(series, session)
      excluded_series?(series) || excluded_by_pattern?(series, session)
    end

    private

    def excluded_series?(series)
      return false if series.nil?

      # "FIA" alone is excluded, but "FIA Formula 2/3" is not
      return true if series == "FIA"

      EXCLUDED_SERIES.any? { |excluded| series.start_with?(excluded) }
    end

    def excluded_by_pattern?(series, session)
      EXCLUDED_PATTERNS.any? do |pattern|
        series&.match?(pattern) || session&.match?(pattern)
      end
    end
  end
end
