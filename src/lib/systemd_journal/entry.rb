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

module SystemdJournal
  # An entry in the systemd journal
  class Entry

    attr_reader :raw, :timestamp, :uid, :gid, :pid, :process_name,
      :cmdline, :unit, :machine_id, :hostname, :message

    BASH_YAST_PATH = Yast::Path.new(".target.bash_output")
    JOURNALCTL = "journalctl --no-pager -o json"

    def initialize(json)
      @raw = JSON.parse(json)
      @uid = @raw["_UID"]
      @gid = @raw["_GID"]
      @pid = @raw["_PID"]
      @process_name = @raw["_COMM"]
      @cmdline = @raw["_CMDLINE"]
      @unit = @raw["_SYSTEMD_UNIT"]
      @machine_id = @raw["_MACHINE_ID"]
      @hostname = @raw["_HOSTNAME"]
      @message = @raw["MESSAGE"]
      @timestamp = Time.at(@raw["__REALTIME_TIMESTAMP"].to_f/1000000)
    end

    # Calls journalctl and returns an array of Entry objects
    #
    # @param journalctl_args [String] Additional arguments to journalctl
    def self.all(journalctl_args = "")
      command = "#{JOURNALCTL} #{journalctl_args}"
      command_result = Yast::SCR.Execute(BASH_YAST_PATH, command)

      # Ignore lines not representing journal entries, like the following
      # -- Reboot --
      json_entries = command_result["stdout"].each_line.select do |line|
        line.start_with?("{")
      end

      json_entries.map do |json|
        new(json)
      end
    end
  end
end
