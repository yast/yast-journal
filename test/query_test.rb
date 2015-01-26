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
require "systemd_journal/query"

describe SystemdJournal::Query do

  describe "#entries" do
    it "returns a filtered set of entries" do
      query = SystemdJournal::Query.new

      expect(query).to receive(:journalctl_options).and_return("options")
      expect(query).to receive(:journalctl_matches).and_return("matches")
      expect(SystemdJournal::Entry).to receive(:all).
        with(options: "options", matches: "matches").and_return("entries")
      expect(query.entries).to eq("entries")
    end
  end

  describe "#journalctl_options" do
    subject { SystemdJournal::Query.new(args).journalctl_options }

    context "when both arguments are nil" do
      let(:args) { {} }

      it "generates an empty hash" do
        expect(subject).to eq({})
      end
    end

    context "when interval is a scalar" do
      let(:args) { { interval: "0dc+1" } }

      it "passes the value directly to 'boot'" do
        expect(subject).to eq({"boot" => "0dc+1"})
      end
    end

    context "when interval is an empty array" do
      let(:args) { { interval: [] } }

      it "generates an empty hash" do
        expect(subject).to eq({})
      end
    end

    context "when interval is an array with one element" do
      let(:args) { { interval: [ "yesterday" ] } }

      it "passes the value to 'since'" do
        expect(subject).to eq({ "since" => "yesterday"})
      end
    end

    context "when interval is an array with two elements" do
      let(:args) {
        { interval: [ "yesterday", "today" ] }
      }

      it "passes the values to 'since' and 'until'" do
        expect(subject).to eq({ "since" => "yesterday", "until" => "today" })
      end
    end

    context "when interval is an array with more than two elements" do
      let(:args) { { interval: [ "yesterday", "today", "another" ] }
      }

      it "the surplus elements are ignored" do
        expect(subject).to eq({ "since" => "yesterday", "until" => "today" })
      end
    end

    context "when interval is an empty hash" do
      let(:args) { { interval: {} } }

      it "generates an empty hash" do
        expect(subject).to eq({})
      end
    end

    context "when interval is a hash with :until" do
      let(:args) { { interval: { until: "today" } } }

      it "passes the value to 'until'" do
        expect(subject).to eq({ "until" => "today" })
      end
    end

    context "when interval is a hash with :until and :since" do
      let(:args) {
        { interval: { until: "today" , since: "yesterday" } } }

      it "passes the values to 'until' and 'since'" do
        expect(subject).to eq({ "since" => "yesterday", "until" => "today" })
      end
    end

    context "when interval is a hash with unrecognized keys" do
      let(:args) { { interval: { whatever: "you want" } } }

      it "ignores the invalid keys" do
        expect(subject).to eq({})
      end
    end

    context "when interval and filters are used" do
      let(:args) {
        {
          interval: -1,
          filters: {
            "whatever" => "you need",
            "unit" => ["two", "units"],
            "match" => "a match"
          }
        }
      }

      it "includes the valid filters" do
        expect(subject["unit"]).to eq(["two", "units"])
      end

      it "ignores the invalid filters" do
        expect(subject["whatever"]).to be_nil
      end

      it "excludes the match key" do
        expect(subject["match"]).to be_nil
      end

      it "includes the processed interval" do
        expect(subject["boot"]).to eq(-1)
      end
    end
  end

  describe "#journalctl_matches" do
    subject { SystemdJournal::Query.new(filters: filters).journalctl_matches }

    context "with empty filters" do
      let(:filters) { {} }

      it "returns nil" do
        expect(subject).to eq(nil)
      end
    end

    context "with non-empty filters" do
      let(:filters) {
        {
          "unit" => "an unit",
          "match" => "a match"
        }
      }

      it "returns the value of the 'match' filter" do
        expect(subject).to eq("a match")
      end
    end
  end
end
