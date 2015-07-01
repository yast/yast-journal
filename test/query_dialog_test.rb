#! /usr/bin/rspec
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

require_relative "spec_helper"
require "systemd_journal/query_dialog"

if !ENV["TRAVIS"]
  describe SystemdJournal::QueryDialog do
    def property(id, property)
      Yast::UI.QueryWidget(Id(id), property)
    end

    # Sends a user input to libyui, optionally running some code before.
    #
    # @param value [Symbol/String] the input expected by UI.UserInput
    # @param pre_hook [Proc] code used to tie the expectations or any other
    #   action to input events. For example, checking the final status of the
    #   dialog before closing it. The effect of an input can be checked on the
    #   pre_hook of the next one to make sure libyui has already applied all the
    #   changes.
    def send_user_input(value, pre_hook: nil)
      expect(Yast::UI).to receive(:UserInput) do
        pre_hook.call if pre_hook
        value
      end
    end

    before(:all) do
      Yast.ui_component = "ncurses"
    end

    before(:each) do
      # Ensure initial status of the dialog:
      # all filter checkboxes unchecked...
      Yast::UI.ChangeWidget(Id("unit"), :Value, false)
      Yast::UI.ChangeWidget(Id("match"), :Value, false)
      Yast::UI.ChangeWidget(Id("priority"), :Value, false)
      # ...and interval set to 'since system's boot'
      Yast::UI.ChangeWidget(Id(:interval), :CurrentButton, "0")
    end

    subject(:dialog) do
      query_presenter = SystemdJournal::QueryPresenter.new
      SystemdJournal::QueryDialog.new(query_presenter)
    end

    describe "#match_value_handler" do
      it "automatically checks the 'match' checkbox when value changes" do
        send_user_input :match_value
        send_user_input :ok,
          pre_hook: -> { expect(property("match", :Value)).to eq true }

        dialog.run
      end
    end

    describe "#unit_value_handler" do
      it "automatically checks the 'unit' checkbox when value changes" do
        send_user_input :unit_value
        send_user_input :ok,
          pre_hook: -> { expect(property("unit", :Value)).to eq true }

        dialog.run
      end
    end

    describe "#until_date_handler" do
      it "automatically checks the dates checkbox when 'until date' changes" do
        send_user_input :until_date
        send_user_input :ok,
          pre_hook: -> { expect(property(:interval, :CurrentButton)).to eq "Hash" }

        dialog.run
      end
    end

    describe "#since_time_handler" do
      it "automatically checks the dates checkbox when 'since time' changes" do
        send_user_input :since_time
        send_user_input :ok,
          pre_hook: -> { expect(property(:interval, :CurrentButton)).to eq "Hash" }

        dialog.run
      end
    end
  end
end
