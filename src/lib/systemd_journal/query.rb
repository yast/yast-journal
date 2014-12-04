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

module SystemdJournal
  # Wrapper for journalctl options.
  class Query

    JOURNALCTL_TIME_FORMAT = "%Y-%m-%d %H:%M:%S"

    FILTERS = [
      {name: :priority, arg: "--priority="},
      {name: :units, arg: "--unit="},
      {name: :matches}
    ]

    attr_reader :interval, :filters, :journalctl_args

    # Creates a new query based on the time interval and some additional filters
    #
    # @param interval [Array,Hash,#to_s] Time interval, can take several forms:
    #   * Array of two elements with starting and ending time
    #   * Hash with two possible keys :since and :until
    #   * An scalar value to be passed to the --boot argument of journalctl
    #   In the first two cases, the values can be Time objects or strings of
    #   any format accepted by journalctl for --until and --since
    # @param filters [Hash] valid keys are :priority, :units and :matches, the
    #   values are strings or array of strings with the format accepted by the
    #   corresponding journalctl argument. If the value is an Array, the
    #   argument will be repeated as many times as needed.
    def initialize(interval: nil, filters: {})
      @interval = interval
      @filters = filters
    end

    # String with a list of arguments for journalctl
    def journalctl_args
      return @journalctl_args if @journalctl_args

      args = []

      # If a interval was specified, translate it to journalctl arguments
      if @interval
        case @interval
        when Array
          args << time_argument(:since, interval[0])
          args << time_argument(:until, interval[1])
        when Hash
          args << time_argument(:since, interval[:since])
          args << time_argument(:until, interval[:until])
        else
          args << "--boot=\"#{@interval}\""
        end
      end
      # Remove empty time arguments
      args.compact!

      # Add filters
      FILTERS.each do |filter|
        # Make sure it's an array and remove nils
        values = [@filters[filter[:name]]].flatten.compact
        values.each do |value|
          args << "#{filter[:arg]}\"#{value}\""
        end
      end
      
      @journalctl_args = args.join(" ")
    end

    # Calls journalctl and returns an Array of Entry objects
    def entries
      Entry.all(journalctl_args)
    end

    def to_s
      "<interval: #{@interval}, filters: #{@filters}>"
    end

  private

    # String representation of a time-based journalctl argument
    # 
    # @param arg [#to_s] name of the argument
    # @param value [#strftime,#to_s]
    def time_argument(arg, value)
      return nil if value.nil?
      if value.respond_to?(:strftime)
        value = "#{value.strftime(JOURNALCTL_TIME_FORMAT)}"
      end
      "--#{arg}=\"#{value}\""
    end
  end
end

