require 'cloudflock-qt'

module CloudFlockQt
  # Public: Class to be used for error notifications.
  class ErrorWindow < Qt::ErrorMessage
    # Public: Width of the results window in pixels.
    WINDOW_WIDTH  = 300
    # Public: Height of the results window in pixels.
    WINDOW_HEIGHT = 150

    # Public: Create and populate the window with results from profiling a
    # remote host.
    def initialize(message)
      super()

      show_message(message)
    end
  end
end
