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

#  To contact Novell about this file by physical or electronic mail,
#  you may find current contact information at www.suse.com

require "y2journal/entry"
require "y2journal/journalctl"

module Y2Journal
  # A more convenient interface to journalctl options
  class Query
    # Valid keys for the filter hash
    VALID_FILTERS = ["unit", "priority", "match"].freeze

    attr_reader :interval, :filters
    # @return [Hash] options in the format expected by Journalctl
    # @see Y2Journal::Journalctl#initialize
    attr_reader :journalctl_options
    # @return [Array] matches in the format expected by Journalctl
    # @see Y2Journal::Journalctl#initialize
    attr_reader :journalctl_matches
    # @return [Array<Entry>] entries read in the last call to #execute
    attr_reader :entries

    # Creates a new query based on the time interval and some additional filters
    #
    # @param interval [Array,Hash,#to_s,nil] Time interval, can take several forms:
    #   * Array of two elements with starting and ending time
    #   * Hash with two possible keys :since and :until
    #   * An scalar value to be passed to the --boot argument of journalctl
    #   * Nil which means no time restriction
    #   In the first two cases, the values can be Time objects or strings of
    #   any format accepted by journalctl for --until and --since
    # @param filters [Hash] The keys must match one of the VALID_FILTERS.
    #   The values are scalars or arrays with the value for the corresponding
    #   journalctl argument. If the value is an Array, the argument will be
    #   repeated as many times as needed.
    # @see Y2Journal::Journalctl#initialize
    def initialize(interval: nil, filters: {})
      unsupported = filters.keys.select { |k| !VALID_FILTERS.include?(k) }
      if !unsupported.empty?
        raise "Unexpected filters for the query: #{unsupported.join(", ")}"
      end
      @filters = filters
      @interval = interval

      @journalctl_matches = if filters["match"].nil?
        []
      else
        [filters["match"]].flatten
      end
      calculate_options

      @entries = []
    end

    # Reads the list of entries from the system
    def execute
      @entries = Entry.all(
        options: journalctl_options,
        matches: journalctl_matches
      )
    end

    # Representation of the query as a string
    def to_s
      "<interval: #{@interval}, filters: #{@filters}, journalctl_options: "\
        "#{@journalctl_options}, journalctl_matches #{@journalctl_matches}>"
    end

    # Array of system's boots registered in the journal.
    #
    # Each boot is represented by a hash with three elements, with all the keys
    # being symbols and all the values being strings.
    #  * id: 32-character identifier
    #  * offset: offset relative to the current boot
    #  * timestamps: timestamps of the first and last message for the boot
    def self.boots
      lines = Journalctl.new({ "list-boots" => nil, "quiet" => nil }, []).output.lines
      lines.map do |line|
        # The 'journalctl --list-boots' output looks like this
        # (slightly stripped down, see test/data for full-length examples)
        # -1 a07ac0f240 Sun 2014-12-14 16:50:09 CET—Mon 2015-01-26 19:18:43 CET
        #  0 24a9a83ecf Mon 2015-01-26 19:55:33 CET—Mon 2015-01-26 20:05:16 CET
        if line.strip =~ /^\s*(-*\d+)\s+(\w+)\s+(.+)$/
          {
            id:         Regexp.last_match[2],
            offset:     Regexp.last_match[1],
            timestamps: Regexp.last_match[3]
          }
        else
          raise "Unexpected output for journalctl --list-boots: #{line}"
        end
      end
    end

  private

    def calculate_options
      @journalctl_options = {}

      # If a interval was specified, translate it to journalctl arguments
      if @interval
        case @interval
        when Array
          @journalctl_options["since"] = @interval[0]
          @journalctl_options["until"] = @interval[1]
        when Hash
          @journalctl_options["since"] = @interval[:since]
          @journalctl_options["until"] = @interval[:until]
        else
          @journalctl_options["boot"] = @interval
        end
      end
      # Remove empty time arguments
      @journalctl_options.reject! { |_, v| v.nil? }

      # Add filters...
      @journalctl_options.merge!(@filters)
      # expect 'match' that is not an option but stored at @journalctl_matches
      @journalctl_options.delete("match")
    end
  end
end
