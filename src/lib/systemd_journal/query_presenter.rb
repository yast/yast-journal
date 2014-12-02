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

require 'systemd_journal/query'
require 'delegate'

module SystemdJournal
  # Presenter for Query adding useful methods for the dialogs
  class QueryPresenter < SimpleDelegator

    include Yast::I18n
    extend Yast::I18n

    # FIXME: using %b is not i18n-friendly
    TIME_FORMAT = "%b %d %H:%M:%S"

    def initialize(interval: "0", filters: {})
      query = Query.new(interval: interval, filters: filters)
      __setobj__(query)
    end

    # User readable description of the current filters
    def filters_description
      # FIXME: this is probably not i18n-friendly with all those commas.
      if filters.empty?
        _("With no additional conditions")
      else
        descriptions = []
        if value = filters[:units]
          descriptions << _("units (%s)") % value.join(", ")
        end
        if value = filters[:matches]
          descriptions << _("files (%s)") % value.join(", ")
        end
        if value = filters[:priority]
          descriptions << _("priority (%s)") % value
        end
        _("Filtering by %s") % descriptions.join(", ")
      end
    end

    # User readable description of the time interval
    def interval_description
      case interval
      when "0"
        _("Since system's boot")
      when "-1"
        _("From previous boot")
      else
        dates = {
          since: interval[:since].strftime(TIME_FORMAT),
          until: interval[:until].strftime(TIME_FORMAT),
        }
        _("Between %{since} and %{until}") % dates
      end
    end

    # Possible intervals for a QueryPresenter object to be used in forms
    #
    # @return [Array<Hash>] each interval is represented by a hash with two keys
    #                 :value and :label
    def self.intervals
      [
        {value: "0", label: _("Since system's boot")},
        {value: "-1", label: _("From previous boot")},
        {value: Hash, label: _("Between these dates")}
      ]
    end

    # Possible filters for a QueryPresenter object to be used in forms
    #
    # @return [Array<Hash>] for each filter there are 4 possible keys
    #   * :name name of the filter
    #   * :label label for the widget used to set the filter
    #   * :multiple boolean indicating if an array is a valid value
    #   * :values optional list of valid values
    def self.filters
      [
        {
          name: :units,
          label: _("For these systemd units"),
          multiple: true
        },
        {
          name: :matches,
          label: _("For these files (executable or device)"),
          multiple: true
        },
        {
          name: :priority,
          label: _("With at least this priority"),
          multiple: false,
          values: ["emerg", "alert", "crit", "err", "warning",
                   "notice", "info", "debug"]
        }
      ]
    end
  end
end

