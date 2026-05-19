# frozen_string_literal: true

module F1Schedule
  # Extracts events from F1.com schedule HTML
  # Coordinates SessionMatcher, EventFilter, and EventNormalizer
  class EventParser
    DAY_PATTERN = /(MONDAY|TUESDAY|WEDNESDAY|THURSDAY|FRIDAY|SATURDAY|SUNDAY)\s+(\d{1,2})\s+(JANUARY|FEBRUARY|MARCH|APRIL|MAY|JUNE|JULY|AUGUST|SEPTEMBER|OCTOBER|NOVEMBER|DECEMBER)/i
    TIME_PATTERN = /(\d{2}):(\d{2})\s*-\s*\d{2}:\d{2}/

    def initialize
      @session_matcher = SessionMatcher.new
      @event_filter = EventFilter.new
      @normalizer = EventNormalizer.new
    end

    def extract_events(html)
      doc = Nokogiri::HTML(html)
      text_content = doc.xpath("//text()").map { |t| t.text.strip }.reject(&:empty?).join(" ")
      year = extract_year(text_content)

      events = []
      day_sections = find_unique_day_sections(text_content)

      day_sections.each do |section|
        date = Date.new(year, section[:month], section[:day])
        parse_day_content(section[:content], date, events)
      end

      events = @normalizer.normalize_ordinal_prefixes(events)
      deduplicate(events)
    end

    private

    def extract_year(text)
      text.match(/\b(20\d{2})\b/)&.captures&.first&.to_i || Date.current.year
    end

    def find_unique_day_sections(text_content)
      day_matches = text_content.to_enum(:scan, DAY_PATTERN).map { Regexp.last_match }

      seen_days = Set.new
      unique_matches = day_matches.select do |match|
        day_key = "#{match[2]}-#{match[3]}"
        if seen_days.include?(day_key)
          false
        else
          seen_days.add(day_key)
          true
        end
      end

      unique_matches.each_with_index.map do |match, idx|
        start_pos = match.end(0)
        end_pos = unique_matches[idx + 1]&.begin(0) || text_content.length

        {
          day: match[2].to_i,
          month: Date::MONTHNAMES.index(match[3].capitalize),
          content: text_content[start_pos...end_pos]
        }
      end
    end

    def parse_day_content(content, date, events)
      time_matches = content.to_enum(:scan, TIME_PATTERN).map { Regexp.last_match }

      time_matches.each_with_index do |time_match, idx|
        event = parse_single_event(content, time_matches, time_match, idx, date)
        events << event if event
      end
    end

    def parse_single_event(content, time_matches, time_match, idx, date)
      local_time = format("%02d:%02d", time_match[1].to_i, time_match[2].to_i)
      prefix_text = extract_prefix_text(content, time_matches, time_match, idx)

      series, session = @session_matcher.split(prefix_text)

      return nil if series.nil? && session.nil?
      return nil if @event_filter.excluded?(series, session)

      {
        date: date,
        local_time: local_time,
        series: @normalizer.normalize_series(series),
        session: @normalizer.normalize_session(session, series)
      }
    end

    def extract_prefix_text(content, time_matches, time_match, idx)
      start_pos = idx.zero? ? 0 : time_matches[idx - 1].end(0)
      end_pos = time_match.begin(0)
      content[start_pos...end_pos]
    end

    def deduplicate(events)
      events.uniq { |e| [ e[:date], e[:series], e[:session] ] }
    end
  end
end
