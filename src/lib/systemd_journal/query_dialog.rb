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

require "yast"
require "ui/dialog"
require "systemd_journal/time_helpers"
require "systemd_journal/query_presenter"

Yast.import "UI"
Yast.import "Label"

module SystemdJournal
  # Dialog allowing the user to set the query used to display the journal
  # entries in SystemdJournal::EntriesDialog
  #
  # It returns a QueryPresenter object.
  #
  # @see SystemdJournal::EntriesDialog
  class QueryDialog < UI::Dialog
    include TimeHelpers

    # Width of the input widgets for the filters
    INPUT_WIDTH = 20

    def initialize(query)
      super()
      textdomain "journal"
      @query = query
    end

    # Main layout
    def dialog_content
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

    # Event callback for the 'ok' button
    def ok_handler
      finish_dialog(query_from_widgets)
    end

    # Registers the callbacks for changes in the UI
    def self.define_event_callbacks
      # Event callbacks for changes in the interval time widgets
      [:until_date, :until_time, :since_date, :since_time].each do |widget|
        define_method(:"#{widget}_handler") do
          # Automatically select the dates-based interval
          Yast::UI.ChangeWidget(Id(:interval), :CurrentButton, "Hash")
        end
      end

      # Event callbacks for changes in the filter fields
      QueryPresenter.filters.each do |filter|
        define_method(:"#{filter[:name]}_value_handler") do
          # Automatically check the corresponding checkbox
          Yast::UI.ChangeWidget(Id(filter[:name]), :Value, true)
        end
      end
    end

    define_event_callbacks

  private

    # Translates the value of the widgets to a new QueryPresenter object
    def query_from_widgets
      interval = Yast::UI.QueryWidget(Id(:interval), :CurrentButton)
      if interval == "Hash"
        interval = {
          since: time_from_widgets_for(:since),
          until: time_from_widgets_for(:until)
        }
      end

      filters = {}
      QueryPresenter.filters.each do |filter|
        name = filter[:name]
        # Skip if the checkbox is not checked
        next unless Yast::UI.QueryWidget(Id(name), :Value)
        # Read the widget...
        value = widget_to_filter(name, filter[:multiple])
        # ...discarding empty values
        filters[name] = value unless value.empty?
      end

      QueryPresenter.new(interval: interval, filters: filters)
    end

    def interval_widget
      RadioButtonGroup(Id(:interval), VBox(*interval_buttons))
    end

    # Array of radio buttons to select the interval
    def interval_buttons
      QueryPresenter.intervals.map do |int|
        Left(
          HBox(
            interval_button(int),
            *interval_additional_widgets(int)
          )
        )
      end
    end

    # Radio button to select a given interval
    #
    # @param int [Hash] interval as returned by QueryPresenter.intervals
    def interval_button(int)
      selected = if int[:value] == Hash
        @query.interval.is_a?(Hash)
      else
        int[:value] == @query.interval
      end
      RadioButton(Id(int[:value].to_s), int[:label], selected)
    end

    # Additional widgets to display after the radio button for a given interval
    #
    # @param int [Hash] interval as returned by QueryPresenter.intervals
    def interval_additional_widgets(int)
      if int[:value] == Hash
        [HSpacing(1)] + dates_widgets
      else
        []
      end
    end

    # Array of widgets for selecting date/time thresholds
    def dates_widgets
      [
        *datetime_widgets_for(:since, since_value),
        Label("-"),
        *datetime_widgets_for(:until, until_value)
      ]
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

    # Widget allowing to set the filters
    def filters_widget
      filters = QueryPresenter.filters.map do |filter|
        name = filter[:name]
        Left(
          HBox(
            CheckBox(Id(name), filter[:form_label], !@query.filters[name].nil?),
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
        ComboBox(id, Opt(:notify), "", items)
      else
        MinWidth(
          INPUT_WIDTH,
          InputField(id, Opt(:notify), "", filter_to_string(name))
        )
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

    # Reads the widget associated to a filter and returns its value, as
    # a String or an Array of strings.
    #
    # @param name [Symbol] name of the filter
    # @param multiple [Boolean] if true, an array will be returned
    def widget_to_filter(name, multiple)
      value = Yast::UI.QueryWidget(Id(:"#{name}_value"), :Value)
      if multiple
        value.split(" ")
      else
        value
      end
    end
  end
end
