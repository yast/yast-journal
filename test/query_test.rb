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
      expect(SystemdJournal::Entry).to receive(:all)
        .with(options: "options", matches: "matches").and_return("entries")
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
        expect(subject).to eq("boot" => "0dc+1")
      end
    end

    context "when interval is an empty array" do
      let(:args) { { interval: [] } }

      it "generates an empty hash" do
        expect(subject).to eq({})
      end
    end

    context "when interval is an array with one element" do
      let(:args) { { interval: ["yesterday"] } }

      it "passes the value to 'since'" do
        expect(subject).to eq("since" => "yesterday")
      end
    end

    context "when interval is an array with two elements" do
      let(:args) do
        { interval: ["yesterday", "today"] }
      end

      it "passes the values to 'since' and 'until'" do
        expect(subject).to eq("since" => "yesterday", "until" => "today")
      end
    end

    context "when interval is an array with more than two elements" do
      let(:args) do
        { interval: ["yesterday", "today", "another"] }
      end

      it "the surplus elements are ignored" do
        expect(subject).to eq("since" => "yesterday", "until" => "today")
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
        expect(subject).to eq("until" => "today")
      end
    end

    context "when interval is a hash with :until and :since" do
      let(:args) do
        { interval: { until: "today", since: "yesterday" } }
      end

      it "passes the values to 'until' and 'since'" do
        expect(subject).to eq("since" => "yesterday", "until" => "today")
      end
    end

    context "when interval is a hash with unrecognized keys" do
      let(:args) { { interval: { whatever: "you want" } } }

      it "ignores the invalid keys" do
        expect(subject).to eq({})
      end
    end

    context "when filters include an invalid key" do
      let(:args) { { filters: { "whatever" => "you need" } } }

      it "raises an error" do
        expect { subject }.to raise_error(RuntimeError)
      end
    end

    context "when interval and filters are used" do
      let(:args) do
        {
          interval: -1,
          filters:  {
            "unit"  => ["two", "units"],
            "match" => "a match"
          }
        }
      end

      it "includes the valid filters" do
        expect(subject["unit"]).to eq(["two", "units"])
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

      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end

    context "with non-empty filters" do
      let(:filters) do
        {
          "unit"  => "an unit",
          "match" => "a match"
        }
      end

      it "returns the value of the 'match' filter as an array" do
        expect(subject).to eq(["a match"])
      end
    end
  end

  describe ".boots" do
    subject { SystemdJournal::Query.boots }

    before do
      allow_to_execute(/journalctl --list-boots/)
        .and_return(cmd_result_for("list-boots-11"))
    end

    it "returns an array of hashes" do
      expect(subject).to be_a(Array)
      expect(subject.map(&:class).uniq).to eq([Hash])
    end

    it "returns a Hash per boot entry" do
      expect(subject.map { |b| b[:offset] })
        .to eq(["-10", "-9", "-8", "-7", "-6", "-5", "-4", "-3", "-2", "-1", "0"])
    end

    it "correctly maps every boot into three fields" do
      expect(subject.first).to eq(

          offset:     "-10",
          id:         "f02631731f744344859a5b7222d815d6",
          timestamps: "Wed 2014-10-01 21:12:23 CEST—Sun 2014-10-05 20:36:49 CEST"

      )
      expect(subject.last).to eq(

          offset:     "0",
          id:         "24a9a89c43d34f859399f7994a233ecf",
          timestamps: "Mon 2015-01-26 19:55:33 CET—Mon 2015-01-26 20:05:16 CET"

      )
    end
  end
end
