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

#  To contact SUSE about this file by physical or electronic mail,
#  you may find current contact information at www.suse.com

require "systemd_journal/time_helpers"

Yast.import "Label"
Yast.import "UI"

module SystemdJournal
  class QueryView
    include TimeHelpers
    include Yast::UIShortcuts
    include Yast::I18n

    INPUT_WIDTH = 20

    def initialize(query)
      @query = query
    end

    # Reads the widget associated to a filter and returns its value, as
    # a String or an Array of strings.
    #
    # @param name [Symbol] name of the filter
    # @param multiple [Boolean] if true, an array will be returned
    def filter(name, multiple)
      # Is the checkbox checked?
      return "" unless Yast::UI.QueryWidget(Id(name), :Value)
      value = Yast::UI.QueryWidget(Id(:"#{name}_value"), :Value)
      if multiple
        value.split(" ")
      else
        value
      end
    end

    def interval
      interval = Yast::UI.QueryWidget(Id(:interval), :CurrentButton)
      if interval == "Hash"
        interval = {
          since: time_from_widgets_for(:since),
          until: time_from_widgets_for(:until)
        }
      end
      interval
    end

    # Main layout
    def content
      VBox(
        # Header
        Heading(_("Entries to display")),
        # Interval
        Frame(
          _("Time interval"),
          interval_widget
        ),
        VSpacing(0.3),
        # Filters
        Frame(
          _("Filters"),
          filters_widget
        ),
        VSpacing(0.3),
        # Footer buttons
        HBox(
          PushButton(Id(:cancel), Yast::Label.CancelButton),
          PushButton(Id(:ok), Yast::Label.OKButton)
        )
      )
    end

    private

    def interval_widget
      RadioButtonGroup(Id(:interval), VBox(*interval_buttons))
    end

    # Array of radio buttons to select the interval
    def interval_buttons
      QueryPresenter.intervals.map do |int|
        selected = int[:value] === @query.interval
        value = int[:value].to_s
        widgets = [RadioButton(Id(value), int[:label], selected)]
        if value == "Hash"
          widgets << HSpacing(1)
          widgets.concat(dates_widgets)
        end

        Left(HBox(*widgets))
      end
    end

    # Array of widgets for selecting date/time thresholds
    def dates_widgets
      [
        *time_widgets_for(:since, since_value),
        Label("-"),
        *time_widgets_for(:until, until_value)
      ]
    end

    # Widget allowing to set the filters
    def filters_widget
      filters = QueryPresenter.filters.map do |filter|
        name = filter[:name]
        Left(
          HBox(
            CheckBox(Id(name), filter[:label], !@query.filters[name].nil?),
            HSpacing(1),
            widget_for_filter(name, filter[:values])
          )
        )
      end
      VBox(*filters)
    end

    # Widget to set the value of a given filter.
    #
    # If the second argument is nil, an input field will be used. Otherwise, a
    # combo box will be returned.
    #
    # @param name [Symbol] name of the filter
    # @param values [Array] optional list of values for the combo box
    def widget_for_filter(name, values = nil)
      id = Id(:"#{name}_value")
      if values
        items = values.map do |value|
          Item(Id(value), value, @query.filters[name] == value)
        end
        ComboBox(id, "", items)
      else
        MinWidth(INPUT_WIDTH, InputField(id, "", filter_to_string(name)))
      end
    end

    # Initial value for the :since widget
    def since_value
      if @query.interval.is_a?(Hash)
        @query.interval[:since]
      else
        QueryPresenter.default_since
      end
    end

    # Initial value for the :until widget
    def until_value
      if @query.interval.is_a?(Hash)
        @query.interval[:until]
      else
        QueryPresenter.default_until
      end
    end

    # Widget to set the value of a given filter.
    #
    # If the second argument is nil, an input field will be used. Otherwise, a
    # combo box will be returned.
    #
    # @param name [Symbol] name of the filter
    # @param values [Array] optional list of values for the combo box
    def widget_for_filter(name, values = nil)
      id = Id(:"#{name}_value")
      if values
        items = values.map do |value|
          Item(Id(value), value, @query.filters[name] == value)
        end
        ComboBox(id, "", items)
      else
        MinWidth(INPUT_WIDTH, InputField(id, "", filter_to_string(name)))
      end
    end

    # String representing the value of a filter.
    #
    # Used to fill the corresponding input field. If the filter has multiple
    # values, they will be concatenated with a whitespace as separator.
    def filter_to_string(name)
      value = @query.filters[name]
      if value.nil?
        ""
      elsif value.is_a?(Array)
        value.join(" ")
      else
        value
      end
    end
  end
end
