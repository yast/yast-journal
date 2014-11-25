require "json"

module SystemdJournal
  # An entry in the systemd journal
  class Entry

    attr_reader :raw, :timestamp, :uid, :gid, :pid, :process_name,
      :cmdline, :unit, :machine_id, :hostname, :message

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
  end
end
