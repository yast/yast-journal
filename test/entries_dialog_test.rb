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
require "systemd_journal/query"

describe SystemdJournal::EntriesDialog do
  let(:query) do
    query = SystemdJournal::Query.new
    allow(query).to receive(:execute)
    allow(query).to receive(:entries).and_return([])
    query
  end
  subject { described_class.new(query: query) }

  describe "#initialize" do
    it "can get optional query" do
      expect{described_class.new(query: query)}.to_not raise_error
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
end
