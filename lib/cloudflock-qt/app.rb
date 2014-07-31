require 'cloudflock-qt'
require 'cloudflock-qt/error'
require 'cloudflock-qt/results'

module CloudFlockQt
  # Public: Class to be used for the main window.
  class App < Qt::MainWindow
    include CloudFlock::App::Common
    include CloudFlock::Remote
    # Public: Width of the main form window in pixels.
    WINDOW_WIDTH  = 300
    # Public: Height of the main form window in pixels.
    WINDOW_HEIGHT = 220
    # Public: Title of the main form window.
    WINDOW_TITLE  = "QtFlock Profile #{CloudFlockQt::VERSION}"

    # Public: Height of each row in the form in pixels
    FORM_LINE_HEIGHT = 30

    # Public: Raised when information provided to log in to a host is
    # incomplete.
    class HostNotConfigured < StandardError; end

    # Public: Set up application state and create the main application window,
    # populating it with the form to take target host details.
    def initialize
      super

      init_instance_variables
      init_ui
    end

    private

    # Internal: Set the default values for instance variables.
    #
    # Returns nothing.
    def init_instance_variables
      @hostname = ''
      @username = 'root'
      @password = ''
      @root_password = ''
      @port = '22'
      @sudo = false

      @lines = 0
    end

    # Internal: Set up the main window and add the form UI for target host
    # definition.
    #
    # Returns nothing.
    def init_ui
      set_window_title WINDOW_TITLE
      resize WINDOW_WIDTH, WINDOW_HEIGHT

      file = menu_bar.add_menu('&File')
      add_menu_item('E&xit', file, :quit)

      build_main_form

      show
    end

    # Internal: Build the form to collect data on the host to profile.
    #
    # Returns nothing.
    def build_main_form
      add_form_line_text('Hostname: ', :@hostname)
      add_form_line_text('Username: ', :@username)
      add_form_pass_text('Password: ', :@password)
      add_form_pass_text('Root Password: ', :@root_password)
      add_form_line_text('Port: ', :@port)

      add_form_line_toggle('Use Sudo', :@sudo)
      add_submit_button('Run Profile') { run_profile }
    end
    
    # Internal: Add an entry to a menu (e.g. 'File'), and assign an action to
    # it.
    #
    # item_text - String containing the text to be displayed.  An '&' character
    #             preceding a character will cause that character to be a
    #             hotkey for the item.
    # menu      - Qt::Menu to contain the new entry.
    # action    - Action to be taken upon triggering the menu item.
    #
    # Returns nothing.
    def add_menu_item(item_text, menu, action)
      item = Qt::Action.new item_text, self
      menu.add_action item
      connect(item, SIGNAL(:triggered), Qt::Application.instance, SLOT(action))
    end

    # Internal: Create a text input field and corrsponding label.
    #
    # item_text - String with which to populate a text label.
    # varname   - Symbol containing the name of the instance variable with
    #             which to associate the form entry.
    #
    # Returns the Qt::LineEdit object.
    def add_form_line_text(item_text, varname)
      @lines += 1

      label = Qt::Label.new self
      label.set_text item_text
      label.adjust_size
      label.move(5, FORM_LINE_HEIGHT * @lines)

      input = Qt::LineEdit.new self
      input.set_geometry 105, FORM_LINE_HEIGHT * @lines - 10, 190, FORM_LINE_HEIGHT
      input.connect(SIGNAL('textChanged(QString)')) do |string|
        instance_variable_set(varname, string)
      end
      input.set_text instance_variable_get(varname)

      input
    end

    # Internal: Wrap add_form_line_text, ensuring the the text display mode is
    # appropriate for passwords.
    #
    # item_text - String with which to populate a text label.
    # varname   - Symbol containing the name of the instance variable with
    #             which to associate the form entry.
    #
    # Returns nothing.
    def add_form_pass_text(item_text, varname)
      add_form_line_text(item_text, varname).echoMode = Qt::LineEdit::Password
    end

    # Internal: Create a toggle button input field.
    #
    # item_text - String which will be displayed on the toggle button.
    # varname   - Symbol containing the name of the instance variable with
    #             which to associate the form entry.
    # block     - Optional block to attach to clicking the toggle.
    #
    # Returns nothing.
    def add_form_line_toggle(item_text, varname, &block)
      @lines += 1

      toggle = Qt::PushButton.new item_text, self
      toggle.set_checkable true
      toggle.set_geometry 5, FORM_LINE_HEIGHT * @lines - 5, 80, 30
      if block.nil?
        toggle.connect(SIGNAL(:clicked)) do
          instance_variable_set(varname, toggle.is_checked)
        end
      else
        toggle.connect(SIGNAL(:clicked), &block)
      end
    end

    # Internal: Create a submit button.
    #
    # item_text - String which will be displayed on the toggle button.
    # varname   - Symbol containing the name of the instance variable with
    #             which to associate the form entry.
    # block     - Optional block to attach to clicking the toggle.
    #
    # Returns nothing.
    def add_submit_button(item_text, &block)
      submit = Qt::PushButton.new item_text, self
      submit.set_geometry 175, FORM_LINE_HEIGHT * @lines - 5, 120, 30
      submit.connect(SIGNAL(:clicked), &block)
    end

    # Internal: Check that all necessary data is present, alerting the user if
    # not.  If everything appears present, attempt to profile the host.
    #
    # Returns nothing.
    def run_profile
      source_host = { hostname: @hostname, username: @username, port: @port,
                      password: @password, sudo: @sudo, ssh_key: '' }
      check_source(source_host)

      source_ssh  = SSH.new(source_host)
      profile     = CloudFlock::Task::ServerProfile.new(source_ssh)
      
      CloudFlockQt::ResultsWindow.new(profile)
    rescue HostNotConfigured => e
      CloudFlockQt::ErrorWindow.new(e.message)
    rescue CloudFlock::Remote::SSH::InvalidHostname
      CloudFlockQt::ErrorWindow.new("Unable to resolve '#{@hostname}'")
    rescue Net::SSH::AuthenticationFailed
      CloudFlockQt::ErrorWindow.new("Unable to log in as '#{@username}'")
    rescue CloudFlock::Remote::SSH::SSHCannotConnect
      CloudFlockQt::ErrorWindow.new("Cannot connect to #{@hostname}:#{@port}")
    end

    # Internal: Verify that all entries necessary for logging in to a remote
    # host are present.
    #
    # Raises HostNotConfigured if any necessary information is not present.
    #
    # Returns nothing.
    def check_source(host)
      [:hostname, :username, :port].each do |option|
        if host[option].to_s.empty?
          raise(HostNotConfigured, "Missing #{option.to_s.capitalize}")
        end
      end
      host[:sudo] = false if host[:username] == 'root'

      # If non-root and using su, the root password is needed
      if host[:username] == 'root' || host[:sudo]
        host[:root_password] = host[:password]
      else
        raise HostNotConfigured if host[:root_password].to_s.empty?
      end
    end
  end
end
