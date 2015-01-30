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
