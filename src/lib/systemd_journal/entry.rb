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
require "systemd_journal/journalctl"

module SystemdJournal
  # An entry in the systemd journal
  class Entry
    attr_reader :raw, :timestamp, :uid, :gid, :pid, :process_name, :cmdline,
      :syslog_id, :unit, :machine_id, :hostname, :message

    JOURNALCTL_OPTS = { "no-pager" => nil, "output" => "json" }

    def initialize(json)
      @raw = JSON.parse(json)
      @uid = @raw["_UID"]
      @gid = @raw["_GID"]
      @pid = @raw["_PID"]
      @process_name = @raw["_COMM"]
      @cmdline = @raw["_CMDLINE"]
      @syslog_id = @raw["SYSLOG_IDENTIFIER"]
      @unit = @raw["_SYSTEMD_UNIT"]
      @machine_id = @raw["_MACHINE_ID"]
      @hostname = @raw["_HOSTNAME"]
      @message = @raw["MESSAGE"]
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
