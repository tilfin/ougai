require 'ougai/colors'

module Ougai
  module Colors
    # Handle the colorization of output, mainly aimed at console formatting. The
    # configuration is split by subject such as +level+, +msg+, or +datetime+.
    class Configuration

      class << self

        # Returns the default Ougai color configuration
        # 'any' severity label decided in Ougai::Logging::Severity#to_label
        def default_configuration
          {
            severity: {
              trace:  Ougai::Colors::BLUE,
              debug:  Ougai::Colors::WHITE,
              info:   Ougai::Colors::CYAN,
              warn:   Ougai::Colors::YELLOW,
              error:  Ougai::Colors::RED,
              fatal:  Ougai::Colors::PURPLE,
              any:    Ougai::Colors::GREEN
            }
          }
        end

      end

      # @param [Hash] configuration: Color configuration. Cannot be nil
      def initialize(configuration = {})
        # key = subject (datetime, msg, level...) and value is a String
        # representing the ANSI color code. String value is not checked
        # so custom colors are allowed but subject to console incompatibility
        @config = Configuration.default_configuration

        configuration.each do |key, val|
          default_val = @config[key]
          # default value is a Hash AND input value is a Hash => merge
          if val.is_a?(Hash) && default_val.is_a?(Hash)
            @config[key] = default_val.merge(val)
          # Input value is assigned because one of the follow
          # 1) input value is not defined in default configuration
          # 2) input value is not a Hash which overrides the default value
          # 3) default value is not a Hash and input is a Hash => Arbitrary design
          else
            @config[key] = val
          end
        end
      end

      # Return a colored text depending on the subject
      # @param [Symbol] subject_key: to define the color to color the text
      # @param [String] text: to be colored text
      # @param [Symbol] severity: log level
      def color(subject_key, text, severity)
        color = get_color_for(subject_key, severity)
        Ougai::Colors.color_text(color, text)
      end

      # Return the color for a given suject and a given severity. This color can
      # then be applied to any text via Ougai::Colors.color_text
      #
      # get_color_for handles color inheritance: if a subject inherit color from
      # another subject, subject value is the symbol refering to the other
      # subject. 
      # !!WARNING!!: Circular references are not checked and lead to infinite loop  
      #
      # @param [Symbol] subject_key: to define the color to color the text
      # @param [Symbol] severity: log level
      # @return requested color String value or +nil+ if not colored
      def get_color_for(subject_key, severity)
        # no colorization
        return nil unless @config.key?(subject_key)
        
        # no severity dependence nor inheritance
        color = @config[subject_key]
        return color if color.is_a? String

        # inheritance from another subject
        return get_color_for(color, severity) if color.is_a? Symbol

        # severity dependent but not inherited value or return +nil+ if
        # configuration is incorrect
        severity = severity.downcase.to_sym
        color[severity]
      end

    end

  end
end
