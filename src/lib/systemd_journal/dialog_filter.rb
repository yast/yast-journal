require 'systemd_journal/query'

module SystemdJournal
  # Class to encapsulate the logic of the filter used in the dialogs.
  class DialogFilter

    include Yast::I18n

    # FIXME: using %b is not i18n-friendly
    TIME_FORMAT = "%b %d %H:%M:%S"

    attr_accessor :source, :time, :since, :until, :unit, :file

    def initialize
      @time = :current_boot
      @source = :all
      @since = Time.now - 24*60*60
      @until = Time.now
      @unit = ""
      @file = ""
    end

    # User readable description of the source
    def source_description
      case @source
      when :all
        _(" - From any source")
      when :unit
        _(" - For the unit %s") % @unit
      when :file
        _(" - For the file %s") % @file
      else
        raise "Unknown option for source filter"
      end
    end

    # User readable description of the time range
    def time_description
      case @time
      when :current_boot
        _(" - Since system's boot")
      when :previous_boot
        _(" - From previous boot")
      when :dates
        dates = {
          since: @since.strftime(TIME_FORMAT),
          until: @until.strftime(TIME_FORMAT)
        }
        _(" - Between %{since} and %{until}") % dates
      else
        raise "Unknown option for time filter"
      end
    end

    # Returns a SystemdJournal::Query object representing the current filter
    # values.
    #
    # @see SystemdJournal::Query
    def to_query
      query = SystemdJournal::Query.new

      case @time
      when :current_boot
        query = query.boot("-0")
      when :previous_boot
        query = query.boot(-1)
      when :dates
        query = query.since(@since).until(@until)
      end

      case @source
      when :unit
        query = query.unit(@unit)
      when :file
        query = query.match(@file)
      end

      query
    end

    def to_s
      attrs = [:source, :time, :since, :until, :unit, :file].map do |attr|
        "#{attr}: \"#{instance_variable_get('@'+attr.to_s)}"
      end
      "{#{attrs.join(' ,')}}"
    end
  end
end

