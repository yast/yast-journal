require "yast"

require "y2journal/entries_dialog"
require "y2journal/query"

params = Yast::WFM.Args
raise "missing param for log entries" if params.empty?

query = Y2Journal::Query.new(interval: "0", filters: { "unit" => params })
Y2Journal::EntriesDialog.new(query: query).run
