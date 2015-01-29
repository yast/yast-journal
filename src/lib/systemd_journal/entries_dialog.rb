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
require "systemd_journal/entries_view"
require "systemd_journal/query_presenter"
require "systemd_journal/query_dialog"

module SystemdJournal
  # Dialog to display journal entries with several filtering options
  class EntriesDialog < UI::Dialog
    def initialize
      super
      textdomain "systemd_journal"

      @query = QueryPresenter.new
      execute_query
      @view = EntriesView.new(@query)
    end

    def dialog_content
      @view.content
    end

    def dialog_options
      @view.dialog_options
    end

    # Event callback for the 'change filter' button.
    def filter_handler
      return unless read_query
      @view.redraw_query
      execute_query
      @view.redraw_table
    end

    # Event callback for change in the content of the search box
    def search_handler
      @view.redraw_table
    end

    # Event callback for the 'refresh' button
    def refresh_handler
      execute_query
      @view.redraw_table
    end

    private

    # Asks the user the new query options using SystemdJournal::QueryDialog.
    #
    # @see SystemdJournal::QueryDialog
    #
    # @return [Boolean] true whether the query has changed
    def read_query
      query = QueryDialog.new(@query).run
      if query
        @query = query
        @view.query = query
        log.info "New query is #{@query}."
        true
      else
        log.info "QueryDialog returned nil. Query is still #{@query}."
        false
      end
    end

    # Reads the journal entries from the system
    def execute_query
      log.info "Executing query #{@query}"
      @query.execute
      log.info "Call to journalctl returned #{@query.entries.size} entries."
    rescue => e
      log.warn e.message
      Yast::Popup.Message(e.message)
    end
  end
end
