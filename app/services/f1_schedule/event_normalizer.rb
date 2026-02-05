# frozen_string_literal: true

module F1Schedule
  # Normalizes series and session names for consistency
  class EventNormalizer
    # F1-specific session name mappings
    F1_SESSION_NORMALIZATIONS = {
      /First\s*Practice|Practice\s*1|FP\s*1/i => "Free Practice 1",
      /Second\s*Practice|Practice\s*2|FP\s*2/i => "Free Practice 2",
      /Third\s*Practice|Practice\s*3|FP\s*3/i => "Free Practice 3",
      /Sprint\s*Qualifying/i => "Sprint Qualifying",
      /Sprint\s*Race|^Sprint$/i => "Sprint",
      /^Qualifying$/i => "Qualifying",
      /^Race$/i => "Race"
    }.freeze

    def normalize_series(name)
      return "Formula 1" if name.nil? || name == "Unknown"

      # Normalize "FORMULA" to "Formula" (keep the number as-is)
      name.strip.gsub(/FORMULA/i, "Formula")
    end

    def normalize_session(name, series)
      return "Unknown" if name.nil? || name.empty?

      normalized = name.dup
      normalized = remove_part_suffix(normalized)
      normalized = remove_brackets(normalized)
      normalized = remove_session_suffix(normalized)
      normalized = titleize_if_all_caps(normalized)
      normalized = apply_f1_normalizations(normalized) if f1_series?(series)
      normalized.strip
    end

    private

    def remove_brackets(text)
      text.gsub(/\s*\([^)]*\)/, "")
    end

    def remove_session_suffix(text)
      text.gsub(/\s*Session\b/i, "")
    end

    def remove_part_suffix(text)
      text.gsub(/\s*-\s*Part\s*\d+\s*$/i, "")
    end

    def titleize_if_all_caps(text)
      return text unless text == text.upcase

      text.split.map(&:capitalize).join(" ")
    end

    def f1_series?(series)
      series.nil? || series.match?(/Formula\s*1/i)
    end

    def apply_f1_normalizations(name)
      F1_SESSION_NORMALIZATIONS.each do |pattern, replacement|
        return replacement if name.match?(pattern)
      end
      name
    end
  end
end
