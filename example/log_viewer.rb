require "yast"

require "systemd_journal/journal_viewer"
require "systemd_journal/entry"

params = Yast::WFM.Args
raise "missing param for log entries" if params.empty?

entries = SystemdJournal::Entry.all(options: {"unit" => params, "boot" => nil})
SystemdJournal::JournalViewer.new(entries).run
