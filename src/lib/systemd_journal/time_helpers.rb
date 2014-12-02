require 'time'

module SystemdJournal
  # Commodity methods for dealing with time fields in the dialogs
  module TimeHelpers

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
end
