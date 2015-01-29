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

require "yast"
require "ui/dialog"
require "systemd_journal/query_view"
require "systemd_journal/query_presenter"

module SystemdJournal
  # Dialog allowing the user to set the query used to display the journal
  # entries in SystemdJournal::EntriesDialog
  #
  # It returns a QueryPresenter object.
  #
  # @see SystemdJournal::EntriesDialog
  class QueryDialog < UI::Dialog
    def initialize(query)
      super()
      textdomain "systemd_journal"
      @query = query
      @view = QueryView.new(@query)
    end

    def dialog_content
      @view.content
    end

    # Event callback for the 'ok' button
    def ok_handler
      finish_dialog(query_from_view)
    end

    private

    # Translates the value of the widgets to a new QueryPresenter object
    def query_from_view
      interval = @view.interval

      filters = {}
      QueryPresenter.filters.each do |filter|
        name = filter[:name]
        # Read the widget...
        value = @view.filter(name, filter[:multiple])
        # ...discarding empty values
        filters[name] = value unless value.empty?
      end

      QueryPresenter.new(interval: interval, filters: filters)
    end
  end
end
