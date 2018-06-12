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
  #   # add also unit to field map to see what is from socket and what is from service
  #   fields = SystemdJournal::JournalViewer.default_fields_map.merge(
  #     unit: "Unit"
  #     priority: "Priority"
  #   )
  #   SystemdJournal::JournalViewer.new(entries, headline: "TFTP log", fields_map: fields).run
  #
  class JournalViewer < UI::Dialog
    extend Yast::I18n

    def initialize(entries, headline: nil, fields_map: nil)
      super()
      textdomain "journal"

      @headline = headline || _("Journal entries")
      @entries = entries
      @fields_map = fields_map || self.class.default_fields_map
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

    def self.default_fields_map
      textdomain "journal"

      {
        formatted_time: _("Time"),
        message:        _("Log Entry")
      }
    end

  protected

    attr_reader :headline
    attr_reader :entries
    attr_reader :fields_map

  private

    # Table widget (plus wrappers) to display log entries
    def table
      headers = fields_map.values

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
        fields = fields_map.keys.map do |field|
          # allow to use methods from presenter and also entry itself
          if entry.respond_to?(field)
            entry.public_send(field)
          else
            entry.entry.public_send(field)
          end
        end
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
