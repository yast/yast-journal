# Copyright (c) 2014 SUSE LLC.
#  All Rights Reserved.

#  This program is free software; you can redistribute it and/or
#  modify it under the terms of version 2 or 3 of the GNU General
#  Public License as published by the Free Software Foundation.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program; if not, contact SUSE LLC.

#  To contact SUSE about this file by physical or electronic mail,
#  you may find current contact information at www.suse.com

module SystemdJournal
  # Wrapper for journalctl invocation
  class Journalctl
    # Agent used internally
    BASH_SCR_PATH = Yast::Path.new(".target.bash_output")
    # Base journalctl command
    COMMAND = "LANG=C journalctl"
    # Format understood by journalctl options
    TIME_FORMAT = "%Y-%m-%d %H:%M:%S"
    # Ordered list of priority values supported by journalctl
    PRIORITIES = ["emerg", "alert", "crit", "err",
                  "warning", "notice", "info", "debug"]

    attr_reader :options, :matches

    # @param options [Hash] The keys are options of the journalctl command like
    #   "boot" or "no-pager" (the long option name should be used). The values
    #   are the corresponding values for the option and can be:
    #
    #    * nil for options without an expected value
    #    * a scalar value (numbers and times/dates would be converted to the
    #      format expected by the journalctl command)
    #    * an array of escalars for options that can be specified multiple times
    #
    # @param matches [Array<String>] list of journalctl matches
    #
    # @example Kernel messages in the last minute for a given device and units
    #   Journalctl.new(
    #     {
    #       "since" => Time.now - 60,
    #       "unit"  => ["local-fs.target", "swap.target"],
    #       "dmesg" => nil
    #     },
    #     ["/dev/sda"]
    #   )
    def initialize(options = {}, matches = [])
      @options = options
      @matches = matches
    end

    # Full journalctl command
    def command
      "#{COMMAND} #{options_string} #{matches_string}".strip.squeeze(" ")
    end

    # Output resulting of executing the command
    def output
      cmd_result = Yast::SCR.Execute(BASH_SCR_PATH, command)

      if cmd_result["exit"].zero?
        cmd_result["stdout"]
      else
        if cmd_result["stderr"] =~ /^Failed to .* timestamp:/
          # Most likely, journalctl bug when an empty list is found
          ""
        else
          raise "Calling journalctl failed: #{cmd_result["stderr"]}"
        end
      end
    end

    private

    def options_string
      return @options_string if @option_string
      strings = []
      @options.each_pair do |option, value|
        if value.nil?
          strings << "--#{option}"
        else
          # In order to handle options with multiple values, make sure it's an
          # array and remove nils (they make no sense with multiple values)
          values = [value].flatten.compact
          values.each do |v|
            v = v.strftime(TIME_FORMAT) if v.respond_to?(:strftime)
            strings << "--#{option}=\"#{v}\""
          end
        end
      end
      @options_string = strings.join(" ")
    end

    def matches_string
      @matches_string ||= @matches.join(" ")
    end
  end
end
