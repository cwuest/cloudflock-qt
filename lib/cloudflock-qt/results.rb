require 'cloudflock-qt'

module CloudFlockQt
  # Public: Class to be used for results windows.
  class ResultsWindow < Qt::Widget
    # Public: Width of the results window in pixels.
    WINDOW_WIDTH  = 400
    # Public: Height of the results window in pixels.
    WINDOW_HEIGHT = 500

    # Public: Create and populate the window with results from profiling a
    # remote host.
    def initialize(profile)
      super()

      init_ui(profile)
    end

    private

    # Internal: Create the results window and text field, then populate it with
    # the results of a host profile.
    #
    # profile - CloudFlock::Task::ServerProfile object.
    #
    # Returns nothing.
    def init_ui(profile)
      hostname = profile.select_entries(/System/, /Hostname/).first.to_s

      set_window_title "Results for #{hostname}"
      resize WINDOW_WIDTH, WINDOW_HEIGHT

      results = Qt::TextEdit.new self
      results.set_geometry 5, 5, WINDOW_WIDTH - 5, WINDOW_HEIGHT - 5
      results.set_text generate_report(profile)

      show
    end

    # Internal: Generate a String representation of the profile run against a
    # remote host.
    #
    # profile - CloudFlock::Task::ServerProfile object.
    #
    # Returns a String.
    def host_info(profile)
      data = profile.map { |section| [section.title, distill_entries(section)] }
      data.map { |section| section.join("\n") }.join("\n\n")
    end

    # Internal: Filter any empty entries from a section, then map the rest to
    # Strings.
    #
    # section - CloudFlock::Task::ServerProfile::Section
    #
    # Returns an Array containing Strings.
    def distill_entries(section)
      non_empty = section.entries.reject { |entry| entry.values.to_s.empty? }
      non_empty.map { |entry| "#{entry.name}: #{entry.values}" }
    end

    # Internal: Produce a human-readable report from the results of profiling a
    # target host.
    #
    # profile - CloudFlock::Task::ServerProfile object.
    #
    # Returns a String.
    def generate_report(profile)
      profile_hash = profile.to_hash
      host_info(profile_hash[:info])
    end
  end
end
