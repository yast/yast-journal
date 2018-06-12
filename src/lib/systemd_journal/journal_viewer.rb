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
require "systemd_journal/entry_presenter"

Yast.import "UI"
Yast.import "Label"
Yast.import "Popup"

module SystemdJournal
  # Dialog to display journal entries. Useful mainly as replacement for
  # log viewer.
  #
  # @example how to display logs for tftp server for current boot
  #   entries = SystemdJournal::Entry.all(options: {"unit" => ["tftp.service", "tftp.socket"], "boot" => nil})
  #   SystemdJournal::JournalViewer.new(entries).run
  #
  class JournalViewer < UI::Dialog
    extend Yast::I18n

    def initialize(entries, headline: nil)
      super()
      textdomain "journal"

      @headline = headline || _("Journal entries")
      @entries = entries
    end

    # Main dialog layout
    def dialog_content
      VBox(
        # Header
        Heading(@headline),
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

  private

    FIELDS_MAP = {
      formatted_time: _("Time"),
      message:        _("Log Entry")
    }
    FIELDS =  FIELDS_MAP.keys
    HEADERS = FIELDS_MAP.values

    # Table widget (plus wrappers) to display log entries
    def table
      headers = HEADERS.map { |h| _(h) }

      Table(
        Id(:table),
        Opt(:keepSorting),
        Header(*headers),
        table_items
      )
    end

    def table_items
      entries_presenters = @entries.map { |e| EntryPresenter.new(e) }
      # Return the result as an array of Items
      entries_presenters.map do |entry|
        fields = FIELDS.map { |f| entry.public_send(f) }
        Item(*fields)
      end
    end

    def footer
      HBox(
        PushButton(Id(:cancel), Yast::Label.QuitButton)
      )
    end
  end
end
