YaST systemd journal module
===========================

[![Workflow Status](https://github.com/yast/yast-journal/workflows/CI/badge.svg?branch=master)](
https://github.com/yast/yast-journal/actions?query=branch%3Amaster)
[![OBS](https://github.com/yast/yast-journal/actions/workflows/submit.yml/badge.svg)](https://github.com/yast/yast-journal/actions/workflows/submit.yml)
[![Coverage Status](https://img.shields.io/coveralls/yast/yast-journal.svg)](https://coveralls.io/r/yast/yast-journal?branch=master)
[![inline docs](http://inch-ci.org/github/yast/yast-journal.svg?branch=master)](http://inch-ci.org/github/yast/yast-journal)

A module for [YaST](http://yast.github.io) to read the systemd journal in a
user-friendly way.

### Notes

- This module can be used by non-root users. By default the non-root users
  do not have the permission to read all journals, to allow specific users
  reading everything add them to the `systemd-journal` user group.

Further information
-------------------

More information about YaST can be found at its
[homepage](http://yast.github.io).
