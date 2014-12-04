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

module SystemdJournal
  describe Query do

    describe "#entries" do
      it "relies on #journalctl_args and Entry.all" do
        query = Query.new
        expect(query).to receive(:journalctl_args).and_return("something")
        expect(Entry).to receive(:all).with("something").and_return("entries")
        expect(query.entries).to eq("entries")
      end
    end

    describe "#journalctl_args" do
      subject { Query.new(args).journalctl_args }

      context "when both arguments are nil" do
        let(:args) { {} }

        it "generates an empty string" do
          expect(subject).to eq("")
        end
      end

      context "when interval is an empty string" do
        let(:args) { { interval: "" } }

        it "generates an empty --boot" do
          expect(subject).to eq("--boot=\"\"")
        end
      end

      context "when interval is a string" do
        let(:args) { { interval: "0dc+1" } }

        it "passes the value directly to --boot" do
          expect(subject).to eq("--boot=\"0dc+1\"")
        end
      end

      context "when interval is a number" do
        let(:args) { { interval: -1 } }

        it "passes the value directly to --boot" do
          expect(subject).to eq("--boot=\"-1\"")
        end
      end

      context "when interval is an empty array" do
        let(:args) { { interval: [] } }

        it "generates an empty string" do
          expect(subject).to eq("")
        end
      end

      context "when interval is an array with one string" do
        let(:args) { { interval: [ "yesterday" ] } }

        it "passes the value directly to --since" do
          expect(subject).to eq("--since=\"yesterday\"")
        end
      end

      context "when interval is an array with one Time object" do
        let(:args) { { interval: [ Time.new(2014,1,2,3,4,5) ] } }

        it "passes the formatted value to --since" do
          expect(subject).to eq("--since=\"2014-01-02 03:04:05\"")
        end
      end

      context "when interval is an array with two elements" do
        let(:args) {
          { interval: [ Time.new(2014,1,2,3,4,5), "yesterday" ] }
        }

        it "passes the formatted values to --since and --until" do
          expect(subject).to eq("--since=\"2014-01-02 03:04:05\" --until=\"yesterday\"")
        end
      end

      context "when interval is an array with more than two elements" do
        let(:args) { { interval: [ "yesterday", "today" ] }
        }

        it "the surplus elements are ignored" do
          expect(subject).to eq("--since=\"yesterday\" --until=\"today\"")
        end
      end

      context "when interval is an empty hash" do
        let(:args) { { interval: {} } }

        it "generates an empty string" do
          expect(subject).to eq("")
        end
      end

      context "when interval is a hash with :until" do
        let(:args) { { interval: { until: Time.new(2014,1,2,3,4,5) } } }

        it "passes the formatted value to --until" do
          expect(subject).to eq("--until=\"2014-01-02 03:04:05\"")
        end
      end

      context "when interval is a hash with :until and :since" do
        let(:args) {
          { interval: { until: Time.new(2014,1,2,3,4,5), since: "yesterday" } } }

        it "passes the formatted values to --until and --since" do
          expect(subject).to eq("--since=\"yesterday\" --until=\"2014-01-02 03:04:05\"")
        end
      end

      context "when interval is a hash with unrecognized keys" do
        let(:args) { { interval: { whatever: "you want" } } }

        it "ignores the invalid keys" do
          expect(subject).to eq("")
        end
      end

      context "when units is a string" do
        let(:args) { { filters: { units: "sshd.service" } } }

        it "adds one --unit argument" do
          expect(subject).to eq("--unit=\"sshd.service\"")
        end
      end

      context "when units is an array" do
        let(:args) { { filters: { units: ["sshd.service", "nfs.service"] } } }

        it "adds several --unit argument" do
          expect(subject).to eq("--unit=\"sshd.service\" --unit=\"nfs.service\"")
        end
      end

      context "when an invalid filter is used" do
        let(:args) { { filters: { whatever: "you need" } } }

        it "ignores the invalid filters" do
          expect(subject).to eq("")
        end
      end

      context "when several filters are used" do
        let(:args) {
          {
            filters: {
              units: "sshd.service",
              matches: ["/dev/sda", "/sbin/arp"],
              priority: 3
            }
          }
        }

        it "combines them all" do
          expect(subject).
            to eq("--priority=\"3\" --unit=\"sshd.service\" \"/dev/sda\" \"/sbin/arp\"")
        end
      end

      context "when several filters and an interval are used" do
        let(:args) {
          {
            interval: "-1",
            filters: { matches: ["/dev/sda"], priority: 3 }
          }
        }

        it "combines them all" do
          expect(subject).to eq("--boot=\"-1\" --priority=\"3\" \"/dev/sda\"")
        end
      end
    end
  end
end
