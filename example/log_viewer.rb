require "yast"

require "systemd_journal/journal_viewer"
require "systemd_journal/entry"

param = Yast::WFM.Args[0]
raise "missing param for log entries" unless param

entries = SystemdJournal::Entry.all(options: {"unit" => param, "boot" => nil})
SystemdJournal::JournalViewer.new(entries).run
