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
SRC_PATH = File.expand_path("../../src", __FILE__)
DATA_PATH = File.join(File.expand_path(File.dirname(__FILE__)), "data")
ENV["Y2DIR"] = SRC_PATH

require "yast"
require "yast/rspec"

# fail fast if a class does not declare textdomain (bsc#1130822)
ENV["Y2STRICTTEXTDOMAIN"] = "1"

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    # If you misremember a method name both in code and in tests,
    # will save you.
    # https://relishapp.com/rspec/rspec-mocks/v/3-0/docs/verifying-doubles/partial-doubles
    #
    # With graceful degradation for RSpec 2
    mocks.verify_partial_doubles = true if mocks.respond_to?(:verify_partial_doubles=)
  end
end

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/test/"
  end

  src_location = File.expand_path("../src", __dir__)
  # track all ruby files under src
  SimpleCov.track_files("#{src_location}/**/*.rb")

  # additionally use the LCOV format for on-line code coverage reporting at CI
  if ENV["CI"] || ENV["COVERAGE_LCOV"]
    require "simplecov-lcov"

    SimpleCov::Formatter::LcovFormatter.config do |c|
      c.report_with_single_file = true
      # this is the default Coveralls GitHub Action location
      # https://github.com/marketplace/actions/coveralls-github-action
      c.single_report_path = "coverage/lcov.info"
    end

    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::LcovFormatter
    ]
  end
end

# Stubbed result of calling a command
def cmd_result_for(name)
  file = File.join(DATA_PATH, "#{name}.out")
  content = File.open(file, encoding: "UTF-8", &:read)
  { "exit" => 0, "stderr" => "", "stdout" => content }
end

# Stubbed result from a call to journalctl which went wrong
def journalctl_error(message)
  { "exit" => 1, "stderr" => message, "stdout" => "" }
end

# Expect the execution of journalctl with the provided options and matches
def expect_journalctl_with(*args)
  expect(Y2Journal::Journalctl).to receive(:new)
    .with(*args).and_call_original
  expect_to_execute(/journalctl/)
end

# Expect a command execution
def expect_to_execute(cmd)
  expect(Yast::SCR).to receive(:Execute).with(path(".target.bash_output"), cmd)
end

# Stub a command execution
def allow_to_execute(cmd)
  allow(Yast::SCR).to receive(:Execute).with(path(".target.bash_output"), cmd)
end

# JSON chunk describing a given entry, read from the example data directory
def json_for(name)
  file = File.join(DATA_PATH, "#{name}-entry.json")
  File.open(file, encoding: "UTF-8", &:read)
end
