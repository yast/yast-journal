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

#  To contact SUSE about this file by physical or electronic mail,
#  you may find current contact information at www.suse.com

require "time"
require_relative "spec_helper"
require "systemd_journal/entry"

describe SystemdJournal::Entry do

  describe ".all" do
    subject { SystemdJournal::Entry.all(args) }

    describe "journalctl invocation" do
      context "when called with no options or matches" do
        let(:args) { {} }

        it "invokes journalctl without filters" do
          expect_journalctl_with({"no-pager" => nil, "output" => "json"}, []).
            and_return(cmd_result_for("journalctl"))
          subject
        end
      end

      context "when called with additional options" do
        let(:args) { { options: { "boot" => 0 } } }

        it "passes the arguments to journalctl" do
          expect_journalctl_with({"no-pager" => nil, "output" => "json", "boot" => 0}, []).
            and_return(cmd_result_for("journalctl"))
          subject
        end
      end

      context "when called with additional matches" do
        let(:args) { { matches: ["/dev/sda"] } }

        it "passes the arguments to journalctl" do
          expect_journalctl_with({"no-pager" => nil, "output" => "json"}, ["/dev/sda"]).
            and_return(cmd_result_for("journalctl"))
          subject
        end
      end
    end

    describe "journalctl parsing" do
      # Arguments are not relevant, we are going to stub the journalctl call
      let(:args) { {} }

      before do
        allow_to_execute(/journalctl/).and_return(cmd_result_for("journalctl"))
      end

      it "ignores journalctl markers" do
        expect(subject.size).to eq(7)
      end

      it "returns an array of Entry objects" do
        expect(subject.all? {|e| e.is_a?(SystemdJournal::Entry)}).to eq(true)
      end

      it "honours the entries order" do
        names = [ "nfs", "wickedd-dhcp4", "wickedd-dhcp6", nil,
                  "systemd-journal", "systemd-journal", nil ]
        expect(subject.map(&:process_name)).to eq(names)
      end
    end
  end

  describe "#initialize" do
    subject { SystemdJournal::Entry.new(json) }
    let(:json) { json_for(entry) }
    # Any entry will work for most general tests
    let(:entry) { "nfs" }

    it "stores the hostname as a string" do
      expect(subject.hostname).to eq("testshost")
    end

    it "stores the timestamp as a Time object" do
      entry_time = Time.parse("2014-11-24 08:07:01 +0100")
      expect(subject.timestamp).to be_a(Time)
      expect(subject.timestamp.to_i).to eq(entry_time.to_i)
    end

    context "when the _COM attribute is included" do
      let(:entry) { "nfs" }

      it "stores it as #process_name" do
        expect(subject.process_name).to eq("nfs")
      end
    end

    context "when the _COM attribute is not present" do
      let(:entry) { "kernel" }

      it "sets process_name to nil" do
        expect(subject.process_name).to be_nil
      end
    end
  end
end
