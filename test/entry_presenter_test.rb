#! rspec
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
require "systemd_journal/entry_presenter"

describe SystemdJournal::EntryPresenter do
  let(:entry) { SystemdJournal::Entry.new(json_for("nfs")) }

  describe "delegation" do
    subject { SystemdJournal::EntryPresenter.new(entry) }

    # Just some examples
    [:raw, :uid, :timestamp, :message].each do |method|
      it "delegates #{method} to its entry" do
        expect(entry).to receive(method).and_return("something")
        expect(subject.send(method)).to eq("something")
      end
    end
  end

  describe "#formatted_time" do
    subject { SystemdJournal::EntryPresenter.new(entry).formatted_time }

    it "returns a string including the time" do
      time = entry.timestamp.strftime("%H:%M:%S")
      expect(subject).to be_a(String)
      expect(subject).to match(time)
    end
  end
end
