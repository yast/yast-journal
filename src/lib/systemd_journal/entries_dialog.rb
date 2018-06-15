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
require "systemd_journal/query_presenter"
require "systemd_journal/query_dialog"

Yast.import "UI"
Yast.import "Label"
Yast.import "Popup"

module SystemdJournal
  # Dialog to display journal entries with several filtering options
  class EntriesDialog < UI::Dialog
    # @param query [QueryPresenter] optional initial query
    def initialize(query: nil)
      super()
      textdomain "journal"

      @query = QueryPresenter.new(query)
      execute_query
    end

    # Main dialog layout
    def dialog_content
      VBox(
        # Header
        Heading(_("Journal entries")),
        # Filters
        Left(
          HBox(
            Label(_("Displaying entries with the following text")),
            HSpacing(1),
            InputField(Id(:search), Opt(:hstretch, :notify), "", "")
          )
        ),
        ReplacePoint(Id(:query), query_description),
        VSpacing(0.3),
        # Log entries
        table,
        VSpacing(0.3),
        # Footer buttons
        footer
      )
    end

    # Dialog options
    def dialog_options
      Opt(:decorated, :defaultsize)
    end

    # Event callback for the 'change filter' button.
    def filter_handler
      return unless read_query
      redraw_query
      execute_query
      redraw_table
    end

    # Event callback for change in the content of the search box
    def search_handler
      redraw_table
    end

    # Event callback for the 'refresh' button
    def refresh_handler
      execute_query
      redraw_table
    end

  private

    # Table widget (plus wrappers) to display log entries
    def table
      headers = @query.columns.map { |c| c[:label] }

      Table(
        Id(:table),
        Opt(:keepSorting),
        Header(*headers),
        table_items
      )
    end

    def table_items
      search = Regexp.escape(Yast::UI.QueryWidget(Id(:search), :Value) || "")

      # Reduce it to an array with only the visible fields
      entries_fields = @query.entries.map do |entry|
        @query.columns.map { |c| entry.send(c[:method]) }
      end
      # Grep for entries matching the search in any visible field
      entries_fields.select! do |fields|
        fields.any? { |f| Regexp.new(search, Regexp::IGNORECASE).match(f) }
      end
      # Return the result as an array of Items
      entries_fields.map { |fields| Item(*fields) }
    end

    def footer
      HBox(
        HWeight(1, PushButton(Id(:filter), _("Change filter..."))),
        HStretch(),
        HWeight(1, PushButton(Id(:refresh), _("Refresh"))),
        HStretch(),
        HWeight(1, PushButton(Id(:cancel), Yast::Label.QuitButton))
      )
    end

    def query_description
      VBox(
        Left(Label(" - #{@query.interval_description}")),
        Left(Label(" - #{@query.filters_description}"))
      )
    end

    def redraw_query
      Yast::UI.ReplaceWidget(Id(:query), query_description)
    end

    def redraw_table
      Yast::UI.ChangeWidget(Id(:table), :Items, table_items)
    end

    # Asks the user the new query options using SystemdJournal::QueryDialog.
    #
    # @see SystemdJournal::QueryDialog
    #
    # @return [Boolean] true whether the query has changed
    def read_query
      query = QueryDialog.new(@query).run
      if query
        @query = query
        log.info "New query is #{@query}."
        true
      else
        log.info "QueryDialog returned nil. Query is still #{@query}."
        false
      end
    end

    # Reads the journal entries from the system
    def execute_query
      log.info "Executing query #{@query.journalctl_options}"
      @query.execute
      log.info "Call to journalctl returned #{@query.entries.size} entries."
    rescue => e
      log.warn e.message
      Yast::Popup.Message(e.message)
    end
  end
end
