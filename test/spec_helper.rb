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

# Set the paths
ENV["Y2DIR"] = File.expand_path("../../src", __FILE__)
DATA_PATH = File.join(File.expand_path(File.dirname(__FILE__)), "data")

require 'yast'
BASH_SCR_PATH = Yast::Path.new(".target.bash_output")

# Stubbed result from a call to journalctl using the example data
def journalctl_result
  file = File.join(DATA_PATH, "journalctl.out")
  content = File.open(file) {|f| f.read }
  {"exit" => 0, "stderr" => "", "stdout" => content}
end

# Stubbed result from a call to journalctl which went wrong
def journalctl_error(message)
  {"exit" => 1, "stderr" => message, "stdout" => ""}
end

# Expect the specified call to journalctl and return a valid result
def expect_journalctl(command)
  expect(Yast::SCR).to receive(:Execute).
    with(BASH_SCR_PATH, command).
    and_return(journalctl_result)
end

# JSON chunk describing a given entry, read from the example data directory
def json_for(name)
  file = File.join(DATA_PATH, "#{name}-entry.json")
  File.open(file) {|f| f.read }
end
