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

require 'systemd_journal/entry'
require 'systemd_journal/journalctl'

module SystemdJournal
  # A more convenient interface to journalctl options
  class Query

    VALID_FILTERS = ["unit", "priority", "match"]

    attr_reader :interval, :filters

    # Creates a new query based on the time interval and some additional filters
    #
    # @param interval [Array,Hash,#to_s] Time interval, can take several forms:
    #   * Array of two elements with starting and ending time
    #   * Hash with two possible keys :since and :until
    #   * An scalar value to be passed to the --boot argument of journalctl
    #   In the first two cases, the values can be Time objects or strings of
    #   any format accepted by journalctl for --until and --since
    # @param filters [Hash] The keys must match one of the VALID_FILTERS.
    #   The values are strings or array of strings with the format accepted by
    #   the corresponding journalctl argument. If the value is an Array, the
    #   argument will be repeated as many times as needed.
    def initialize(interval: nil, filters: {})
      @interval = interval
      # Make sure the keys are strings
      @filters = Hash[filters.map {|k,v| [k.to_s, v] }]
      # Filter out unsuported filters
      @filters.delete_if {|k,v| !VALID_FILTERS.include?(k) }
    end

    # Hash of options in the format expected by SystemdJournal::Journalctl
    def journalctl_options
      return @journalctl_options if @journalctl_options

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
      @journalctl_options.reject! {|k,v| v.nil? }

      # Add filters...
      @journalctl_options.merge!(@filters)
      # ...expect 'match'
      @journalctl_options.delete("match")

      @journalctl_options
    end

    # Array of matches in the format expected by SystemdJournal::Journalctl
    def journalctl_matches
      @filters["match"]
    end

    # Calls journalctl and returns an Array of Entry objects
    def entries
      Entry.all(options: journalctl_options, matches: journalctl_matches)
    end

    def to_s
      "<interval: #{@interval}, filters: #{@filters}>"
    end
  end
end

