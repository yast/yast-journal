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

Yast.import "UI"
Yast.import "Label"
Yast.import "Popup"

module SystemdJournal
  class EntriesView
    include Yast::UIShortcuts
    include Yast::I18n

    attr_writer :query

    def initialize(query)
      @query = query
    end

    # Main dialog layout
    def content
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
      search = Yast::UI.QueryWidget(Id(:search), :Value) || ""

      # Reduce it to an array with only the visible fields
      entries_fields = @query.entries.map do |entry|
        @query.columns.map { |c| entry.send(c[:method]) }
      end
      # Grep for entries matching 'search' in any visible field
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
  end
end
