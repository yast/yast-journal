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

require_relative "spec_helper"
require "systemd_journal/journalctl"

describe SystemdJournal::Journalctl do
  describe "#output" do
    subject { SystemdJournal::Journalctl.new.output }

    before do
      allow_to_execute(/journalctl/).and_return(result)
    end

    context "when journalctl works" do
      let(:result) { cmd_result_for("journalctl") }

      it "returns the command output" do
        expect(subject).to eq(result["stdout"])
      end
    end

    context "when journalctl reports 'Failed to determine timestamp'" do
      let(:result) do
        journalctl_error("Failed to determine timestamp: Cannot assign")
      end

      it "returns an empty string" do
        expect(subject).to eq("")
      end
    end

    context "when journalctl reports 'Failed to get realtime timestamp'" do
      let(:result) do
        journalctl_error("Failed to get realtime timestamp: Cannot assign")
      end

      it "returns an empty string" do
        expect(subject).to eq("")
      end
    end

    context "when journalctl reports an unexpected error" do
      let(:result) do
        journalctl_error("There are always more ways to crash")
      end

      it "raises RuntimeError" do
        expect { subject }.to raise_error(RuntimeError)
      end
    end
  end

  describe "#command" do
    subject { SystemdJournal::Journalctl.new(options, matches).command }

    describe "generation of journalctl matches" do
      let(:options) { {} }
      let(:matches) { ["/dev/sda", "/dev/sdb"] }

      it "adds the strings separated by space at the end of the command" do
        expect(subject).to match(/journalctl \/dev\/sda \/dev\/sdb$/)
      end
    end

    describe "generation of journalctl options" do
      let(:matches) { [] }
      let(:options) { { "option" => option } }

      context "when receiving an option with a nil value" do
        let(:option) { nil }

        it "includes the option without assigned value" do
          expect(subject).to match(/journalctl --option/)
        end
      end

      context "when receiving an option with a string value" do
        let(:option) { "value" }

        it "assigns the string" do
          expect(subject).to match(/journalctl --option=\"value\"/)
        end
      end

      context "when receiving an option with a numeric value" do
        let(:option) { -1 }

        it "assigns the value as a string" do
          expect(subject).to match(/journalctl --option=\"-1\"/)
        end
      end

      context "when receiving an option with a time object" do
        let(:option) { Time.new(2014, 1, 2, 3, 4, 5) }

        it "assigns the formatted time" do
          expect(subject).to match(/journalctl --option=\"2014-01-02 03:04:05\"/)
        end
      end

      context "when receiving an option with an array" do
        let(:option) { ["value", Time.new(2014, 1, 2, 3, 4, 5)] }

        it "includes the option as many times as needed" do
          expect(subject).to include('--option="2014-01-02 03:04:05"')
          expect(subject).to include('--option="value"')
        end
      end
    end
  end
end
