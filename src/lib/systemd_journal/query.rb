require "yast"
require "systemd_journal/entry"

Yast.import "SCR"

module SystemdJournal
  # Wrapper for journalctl usage. REIMPLEMENTATION (AND API CHANGE) PENDING
  #
  # As an experiment, I tried to mimic as closely as possible the API of
  # ActiveRecord::Relation (familiar to many Ruby developers) and even its
  # implementation. But the result ended up being a mess.
  class Query

    YAST_PATH = Yast::Path.new(".target.bash_output")
    JOURNALCTL = "journalctl --no-pager -o json"
    JOURNALCTL_TIME_FORMAT = "%Y-%m-%d %H:%M:%S"

    SINGLE_FILTERS = {
      boot: "--boot=",
      priority: "--priority=",
      since: "--since=",
      until: "--until="
    }
    MULTIPLE_FILTERS = {
      match: "",
      unit: "--unit="
    }

    def initialize
      # Storage of multiple filters
      @unit = []
      @match = []
      # Storage of single filters
      @priority = @since = @until = @boot = nil
    end

    # Methods for an ActiveRecord:Relation-like interface
    #

    def priority(value)
      dup.priority!(value)
    end

    def since(value)
      dup.since!(value)
    end

    def until(value)
      dup.until!(value)
    end

    def boot(value)
      dup.boot!(value)
    end

    def match(value)
      dup.match!(value)
    end

    def unit(value)
      dup.unit!(value)
    end

    # Full journalctl command
    def command
      command = "#{JOURNALCTL} #{cmd_args.join(' ')}"
    end

    # Calls journalctl and returns an array of SystemdJournal::Entry objects
    def entries
      command_result = Yast::SCR.Execute(YAST_PATH, command)
      # Ignore lines not representing journal entries, like the following
      # -- Reboot --
      json_entries = command_result["stdout"].each_line.select do |line|
        line.start_with?("{")
      end
      json_entries.map do |json|
        Entry.new(json)
      end
    end

    SINGLE_FILTERS.keys.each do |name|
      define_method(:"#{name}!") do |value|
        instance_variable_set(:"@#{name}", value)
        self
      end
    end

    MULTIPLE_FILTERS.keys.each do |name|
      define_method(:"#{name}!") do |value|
        instance_variable_get(:"@#{name}").push(value)
        self
      end
    end

    def dup
      copy = super
      MULTIPLE_FILTERS.keys.each do |name|
        clone = instance_variable_get("@#{name}").dup
        copy.instance_variable_set("@#{name}", clone)
      end
      copy
    end

  private
  
    # List of arguments to the journalctl command
    def cmd_args
      # First, the arguments that can appear only once
      args = SINGLE_FILTERS.map do |name, arg|
        value = instance_variable_get(:"@#{name}")
        cmd_arg(arg, value)
      end
      # Then, arguments that can be specified several times
      MULTIPLE_FILTERS.each do |name, arg|
        next if arg.empty?
        values = instance_variable_get(:"@#{name}")
        args.concat(values.map {|value| cmd_arg(arg, value) })
      end
      # And finally, the command can end with several matches
      args.concat(@match)

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
