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
require "y2journal/entries_dialog"
require "y2journal/query"

describe Y2Journal::EntriesDialog do
  let(:query) do
    query = Y2Journal::Query.new
    allow(query).to receive(:execute)
    allow(query).to receive(:entries).and_return([])
    query
  end

  # journalctl error message
  let(:details) { "failed!" }
  subject { described_class.new(query: query) }

  describe "#initialize" do
    it "can get optional query" do
      expect { described_class.new(query: query) }.to_not raise_error
    end

    it "executes query" do
      expect(query).to receive(:execute)

      described_class.new(query: query)
    end
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
      expect_any_instance_of(Y2Journal::QueryDialog).to receive(:run)
        .and_raise(Y2Journal::JournalctlException, details)
      expect(Yast2::Popup).to receive(:show).with(anything, details: details)

      # mock the other methods
      allow(subject).to receive(:redraw_query)
      allow(subject).to receive(:execute_query)
      allow(subject).to receive(:redraw_table)

      expect { subject.filter_handler }.to_not raise_error
    end
  end
end
