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

require "json"
require "yast"
require "y2journal/journalctl"

module Y2Journal
  # An entry in the systemd journal
  class Entry
    attr_reader :raw, :timestamp, :uid, :gid, :pid, :process_name, :cmdline,
      :syslog_id, :unit, :machine_id, :hostname, :message, :priority

    # Used internally to get the entries in a parseable format
    JOURNALCTL_OPTS = { "no-pager" => nil, "output" => "json" }.freeze

    JSON_MAPPING = {
      uid:          "_UID",
      gid:          "_GID",
      pid:          "_PID",
      process_name: "_COMM",
      cmdline:      "_CMDLINE",
      syslog_id:    "SYSLOG_IDENTIFIER",
      unit:         "UNIT",
      machine_id:   "_MACHINE_ID",
      hostname:     "_HOSTNAME",
      message:      "MESSAGE",
      priority:     "PRIORITY"
    }.freeze

    private_constant :JSON_MAPPING

    def initialize(json)
      @raw = JSON.parse(json)
      JSON_MAPPING.each_pair do |variable, json_key|
        instance_variable_set(:"@#{variable}", @raw[json_key])
      end
      @timestamp = Time.at(@raw["__REALTIME_TIMESTAMP"].to_f / 1_000_000)
    end

    # Calls journalctl and returns an array of Entry objects
    #
    def self.all(options: {}, matches: [])
      output = Journalctl.new(options.merge(JOURNALCTL_OPTS), matches).output
      # Ignore lines not representing journal entries, like the following
      # -- Reboot --
      json_entries = output.each_line.select do |line|
        line.start_with?("{")
      end

      json_entries.map do |json|
        new(json)
      end
    end
  end
end
