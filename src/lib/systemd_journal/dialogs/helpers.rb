require 'time'
require 'systemd_journal/query'

module Helpers
  
  # FIXME: Do we have i18n support for time formats?
  TIME_FORMAT = "%b %d %H:%M:%S"

  def source_description(filter)
    case filter[:source]
    when :all
      _(" - From any source")
    when :unit
      _(" - For the unit %s") % filter[:unit]
    when :file
      _(" - For the file %s") % filter[:file]
    else
      raise "Unknown option for source filter"
    end
  end

  def time_description(filter)
    case filter[:time]
    when :current_boot
      _(" - Since system's boot")
    when :previous_boot
      _(" - From previous boot")
    when :dates
      dates = {
        since: filter[:since].strftime(TIME_FORMAT),
        until: filter[:until].strftime(TIME_FORMAT)
      }
      _(" - Between %{since} and %{until}") % dates
    else
      raise "Unknown option for time filter"
    end
  end

  def journal_query(filter)
    query = SystemdJournal::Query.new

    case filter[:time]
    when :current_boot
      query = query.boot("-0")
    when :previous_boot
      query = query.boot(-1)
    when :dates
      query = query.since(filter[:since]).until(filter[:until])
    end

    case filter[:source]
    when :unit
      query = query.unit(filter[:unit])
    when :file
      query = query.match(filter[:file])
    end

    query
  end

  # Array of radio buttons
  #
  # @param options [Array] Array of options. Every option is an array where the
  #                       first element represents the id, the second the label
  #                       and the rest elements are optional widgets.
  # @param value [Object] Id of the currently selected radio button.
  def radio_buttons_for(options, value: nil)
    options.map do |id, label, *widgets|
      Left(
        HBox(
          RadioButton(Id(id), label, value == id),
          *widgets
        )
      )
    end
  end

  # Array of widgets representing one time field.
  #
  # The result depends on the used UI, since not all widgets are available
  # in all interfaces.
  def time_widgets_for(field, value)
    date = value.strftime("%Y-%m-%d")
    time = value.strftime("%H:%M:%S")
    widgets = []

    # DateField widget is not available in ncurses interface
    if Yast::UI.HasSpecialWidget(:DateField)
      widgets << DateField(Id(:"#{field}_date"), "", date)
    else
      widgets << MinWidth(11, InputField(Id(:"#{field}_date"), "", date))
    end
    # TimeField widget is not available in ncurses interface
    if Yast::UI.HasSpecialWidget(:TimeField)
      widgets << TimeField(Id(:"#{field}_time"), "", time)
    else
      widgets << MinWidth(9, InputField(Id(:"#{field}_time"), "", time))
    end
    widgets
  end

  # Reads the widgets representing a time
  #
  # @returns [Time] Value specified by the user
  def time_from_widgets_for(field)
    Time.parse(
      Yast::UI.QueryWidget(Id(:"#{field}_date"), :Value) +
      " " +
      Yast::UI.QueryWidget(Id(:"#{field}_time"), :Value)
    )
  end
end
