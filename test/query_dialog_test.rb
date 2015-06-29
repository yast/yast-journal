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

describe SystemdJournal::QueryDialog do
  def property(id, property)
    Yast::UI.QueryWidget(Id(id), property)
  end

  def input(value, after_doing: nil)
    expect(Yast::UI).to receive(:UserInput) do
      after_doing.call if after_doing
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

  subject(:dialog) { SystemdJournal::QueryDialog.new(SystemdJournal::QueryPresenter.new) }

  describe "#match_value_handler" do
    it "automatically checks the 'match' checkbox when value changes" do
      input :match_value
      input :ok,
        after_doing: -> { expect(property("match", :Value)).to eq true }

      dialog.run
    end
  end

  describe "#unit_value_handler" do
    it "automatically checks the 'unit' checkbox when value changes" do
      input :unit_value
      input :ok,
        after_doing: -> { expect(property("unit", :Value)).to eq true }

      dialog.run
    end
  end

  describe "#until_date_handler" do
    it "automatically checks the dates checkbox when 'until date' changes" do
      input :until_date
      input :ok,
        after_doing: -> { expect(property(:interval, :CurrentButton)).to eq "Hash" }

      dialog.run
    end
  end

  describe "#since_time_handler" do
    it "automatically checks the dates checkbox when 'since time' changes" do
      input :since_time
      input :ok,
        after_doing: -> { expect(property(:interval, :CurrentButton)).to eq "Hash" }

      dialog.run
    end
  end
end
