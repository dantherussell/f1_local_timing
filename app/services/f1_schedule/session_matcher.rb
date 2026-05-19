# frozen_string_literal: true

module F1Schedule
  # Splits concatenated text into series and session components
  # Patterns are organized by category for clarity and maintainability
  class SessionMatcher
    # Patterns grouped by category, checked in order within each group
    # More specific patterns come before general ones
    PRACTICE_PATTERNS = [
      /FIRST PRACTICE/i,
      /SECOND PRACTICE/i,
      /THIRD PRACTICE/i,
      /FREE PRACTICE/i,
      /PRACTICE SESSION/i,
      /PRACTICE/i
    ].freeze

    SPRINT_PATTERNS = [
      /SPRINT QUALIFYING/i,
      /SPRINT RACE/i,
      /SPRINT SHOOTOUT/i,
      /SPRINT(?!\s*Challenge)/i  # Negative lookahead: don't match "Sprint Challenge" series
    ].freeze

    QUALIFYING_PATTERNS = [
      /QUALIFYING SESSION/i,
      /QUALIFYING/i
    ].freeze

    RACE_PATTERNS = [
      /FEATURE RACE/i,
      /OPENING RACE/i,
      /REVERSE GRID RACE/i,
      /FIRST RACE/i,
      /SECOND RACE/i,
      /THIRD RACE/i,
      /FOURTH RACE/i,
      /GRAND PRIX/i,
      /RACE/i
    ].freeze

    # These are matched but typically filtered out by EventFilter
    EXCLUDED_SESSION_PATTERNS = [
      /Team Pit Stop/i,
      /Pit Lane Walk/i,
      /Track Tour/i,
      /Presentation/i,
      /Parade/i,
      /Anthem/i,
      /Press Conference/i,
      /Hot Laps/i
    ].freeze

    # All patterns in priority order
    def all_patterns
      @all_patterns ||= [
        *PRACTICE_PATTERNS,
        *SPRINT_PATTERNS,
        *QUALIFYING_PATTERNS,
        *RACE_PATTERNS,
        *EXCLUDED_SESSION_PATTERNS
      ]
    end

    # Splits text like "Formula 1QUALIFYING SESSION" into ["Formula 1", "QUALIFYING SESSION"]
    # Returns [series, session] where either may be nil
    def split(text)
      return [ nil, nil ] if text.nil? || contains_artifacts?(text)

      cleaned = normalize_whitespace(text)
      return [ nil, nil ] if cleaned.empty?

      match = find_session_match(cleaned)

      if match
        series = cleaned[0...match.begin(0)].strip
        session = cleaned[match.begin(0)..].strip
        series = nil if series.empty?
        [ series, session ]
      else
        [ cleaned.strip, nil ]
      end
    end

    private

    def contains_artifacts?(text)
      text.include?("className") || text.include?('":"')
    end

    def normalize_whitespace(text)
      text.gsub(/[[:space:]]+/, " ")
          .gsub(/Local time/i, "")
          .strip
    end

    def find_session_match(text)
      all_patterns.each do |pattern|
        match = text.match(pattern)
        return match if match
      end
      nil
    end
  end
end
