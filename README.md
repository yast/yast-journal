YaST systemd journal module
===========================

[![Travis Build](https://travis-ci.org/yast/yast-journal.svg?branch=master)](https://travis-ci.org/yast/yast-journal)
[![Coverage Status](https://coveralls.io/repos/yast/yast-journal/badge.svg?branch=master&service=github)](https://coveralls.io/github/yast/yast-journal?branch=master)
[![Code Climate](https://codeclimate.com/github/yast/yast-journal/badges/gpa.svg)](https://codeclimate.com/github/yast/yast-journal)

A module for [YaST](http://yast.github.io) to read the systemd journal in a
user-friendly way.

### Notes

- This module can be used by non-root users. By default the non-root users
  do not have the permission to read the journal, to allow specific users
  reading the journal add them to the `systemd-journal` user group.

Further information
-------------------

More information about YaST can be found at its
[homepage](http://yast.github.io).
