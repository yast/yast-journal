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

require "time"

module Y2Journal
  # Commodity methods for dealing with time fields in the dialogs
  module TimeHelpers
    # Array of widgets representing one time field.
    #
    # The result depends on the used UI, since not all widgets are available
    # in all interfaces.
    def datetime_widgets_for(field, value)
      [
        date_widget_for(:"#{field}_date", value),
        time_widget_for(:"#{field}_time", value)
      ]
    end

    # Widget representing one time field (without the date part)
    #
    # The result depends on the used UI, since not all widgets are available
    # in all interfaces.
    def time_widget_for(field, value)
      time = value.strftime("%H:%M:%S")

      # TimeField widget is not available in ncurses interface
      if Yast::UI.HasSpecialWidget(:TimeField)
        TimeField(Id(field), Opt(:notify), "", time)
      else
        MinWidth(9, InputField(Id(field), Opt(:notify), "", time))
      end
    end

    # Widget representing one date field.
    #
    # The result depends on the used UI, since not all widgets are available
    # in all interfaces.
    def date_widget_for(field, value)
      date = value.strftime("%Y-%m-%d")

      # DateField widget is not available in ncurses interface
      if Yast::UI.HasSpecialWidget(:DateField)
        DateField(Id(field), Opt(:notify), "", date)
      else
        MinWidth(11, InputField(Id(field), Opt(:notify), "", date))
      end
    end

    # Reads the widgets representing a time
    #
    # @return [Time] Value specified by the user
    def time_from_widgets_for(field)
      Time.parse(
        Yast::UI.QueryWidget(Id(:"#{field}_date"), :Value) +
        " " +
        Yast::UI.QueryWidget(Id(:"#{field}_time"), :Value)
      )
    end
  end
end
