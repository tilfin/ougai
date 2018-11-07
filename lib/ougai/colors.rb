# frozen_string_literal: true

module Ougai
  # List of available foreground and background colors along with font modifier.
  #
  # Non-bold font colors do not use \e[0;{value}m because it seems to be
  # incompatible with background colors: \e[41m\e[0;34mtext\e[0m does not print
  # background red while \e[41m\e[34mtext\e[0m works. However, to put font in
  # bold/bright mode, \e[41m\e[1;34mtext\e[0m works
  # => Tested on Windows PowerShell and MinGW64
  #
  # Source: https://gist.github.com/chrisopedia/8754917
  module Colors
    # Reset formatting. To be appended after every formatted text
    RESET             = "\e[0m" 
    # Foreground colors
    BLACK             = "\e[30m"
    RED               = "\e[31m"
    GREEN             = "\e[32m"
    YELLOW            = "\e[33m"
    BLUE              = "\e[34m"
    PURPLE            = "\e[35m"
    CYAN              = "\e[36m"
    WHITE             = "\e[37m"
    BOLD_RED          = "\e[1;31m"
    BOLD_GREEN        = "\e[1;32m"
    BOLD_YELLOW       = "\e[1;33m"
    BOLD_BLUE         = "\e[1;34m"
    BOLD_MAGENTA      = "\e[1;35m"
    BOLD_CYAN         = "\e[1;36m"
    BOLD_WHITE        = "\e[1;37m"
    # Background colors
    BG_BLACK          = "\e[40m"
    BG_RED            = "\e[41m"
    BG_GREEN          = "\e[42m"
    BG_YELLOW         = "\e[43m"
    BG_BLUE           = "\e[44m"
    BG_MAGENTA        = "\e[45m"
    BG_CYAN           = "\e[46m"
    BG_WHITE          = "\e[47m"

    class << self
      # Color a text
      # @param [String] color: color to prepend. Color can be from the list
      #         above or have a complete custom value depending on the terminal
      # @param [String] text: text to be colored
      def color_text(color, text)
        return text if color.nil?

        color + text + Ougai::Colors::RESET
      end
    end

  end
end
