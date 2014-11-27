require "yast"
require "systemd_journal/entry"

Yast.import "SCR"

module SystemdJournal
  # Wrapper for journalctl usage.
  #
  # Check Query::SINGLE_FILTERS and Query::MULTIPLE_FILTERS for a list of the
  # attributes supported to filter the journal query.
  class Query

    SINGLE_FILTERS = {
      boot: "--boot=",
      priority: "--priority=",
      since: "--since=",
      until: "--until="
    }
    MULTIPLE_FILTERS = {
      matches: "",
      units: "--unit="
    }

    BASH_YAST_PATH = Yast::Path.new(".target.bash_output")
    JOURNALCTL = "journalctl --no-pager -o json"
    JOURNALCTL_TIME_FORMAT = "%Y-%m-%d %H:%M:%S"

    attr_accessor *SINGLE_FILTERS.keys
    attr_accessor *MULTIPLE_FILTERS.keys

    def initialize
      # Storage of single filters
      SINGLE_FILTERS.keys.each do |attr|
        send(:"#{attr}=", nil)
      end
      # Storage of multiple filters
      MULTIPLE_FILTERS.keys.each do |attr|
        send(:"#{attr}=", [])
      end
    end

    # Full journalctl command
    def command
      command = "#{JOURNALCTL} #{cmd_args.join(' ')}"
    end

    # Calls journalctl and returns an array of SystemdJournal::Entry objects
    def entries
      command_result = Yast::SCR.Execute(BASH_YAST_PATH, command)
      # Ignore lines not representing journal entries, like the following
      # -- Reboot --
      json_entries = command_result["stdout"].each_line.select do |line|
        line.start_with?("{")
      end
      json_entries.map do |json|
        Entry.new(json)
      end
    end

  private
  
    # List of arguments to the journalctl command
    def cmd_args
      # First, the arguments that can appear only once
      args = SINGLE_FILTERS.map do |name, arg|
        cmd_arg(arg, send(name))
      end
      # Then, arguments that can be specified several times
      MULTIPLE_FILTERS.each do |name, arg|
        next if arg.empty?
        values = send(name)
        args.concat(values.map {|value| cmd_arg(arg, value) })
      end
      # And finally, the command can end with several matches
      args.concat(@matches)

      args.reject(&:empty?)
    end

    # Argument to the journalctl command
    def cmd_arg(arg, value)
      return "" if value.nil?

      if value.respond_to?(:strftime)
        value = "\"#{value.strftime(JOURNALCTL_TIME_FORMAT)}\""
      end

      "#{arg}#{value}"
    end
  end
end
