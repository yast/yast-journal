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

#  To contact SUSE about this file by physical or electronic mail,
#  you may find current contact information at www.suse.com

require_relative "spec_helper"
require "systemd_journal/entries_dialog"
require "systemd_journal/journalctl_exception"

describe SystemdJournal::EntriesDialog do
  # journalctl error message
  let(:details) { "failed!" }

  before do
    # the query is executed in the constructor
    allow_any_instance_of(SystemdJournal::Query).to receive(:execute)
  end

  describe "#dialog_content" do
    it "returns Term" do
      expect(subject.dialog_content).to be_a(Yast::Term)
    end
  end

  describe "#dialog_options" do
    it "returns Term" do
      expect(subject.dialog_options).to be_a(Yast::Term)
    end
  end

  describe "#filter_handler" do
    it "reports an error when journalctl fails" do
      expect_any_instance_of(SystemdJournal::QueryDialog).to receive(:run)
        .and_raise(SystemdJournal::JournalctlException, details)
      expect(Yast::Popup).to receive(:MessageDetails).with(anything, details)

      # mock the other methods
      allow(subject).to receive(:redraw_query)
      allow(subject).to receive(:execute_query)
      allow(subject).to receive(:redraw_table)

      expect { subject.filter_handler }.to_not raise_error
    end
  end
end
