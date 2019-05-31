#
# spec file for package yast2-journal
#
# Copyright (c) 2014 SUSE LLC.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via https://bugs.opensuse.org/
#


Name:           yast2-journal
Version:        4.2.1
Release:        0
Group:          System/YaST
License:        GPL-2.0 or GPL-3.0
Url:            https://github.com/yast/yast-journal
Summary:        YaST2 - Reading of systemd journal

Source0:        %{name}-%{version}.tar.bz2

BuildRequires:  update-desktop-files
# Yast::Builtins::strftime
BuildRequires:  yast2-ruby-bindings >= 3.1.38
BuildRequires:  yast2-devtools
BuildRequires:  yast2
#for install task
BuildRequires:  rubygem(yast-rake)
# for tests
BuildRequires:  rubygem(rspec)
# First version with Yast::UI.OpenUI
BuildRequires:  libyui-ncurses >= 2.47.1
# libyui-terminal
BuildRequires:  libyui-ncurses-tools

# First version with base Dialog class
Requires:       yast2 >= 3.1.117
# Yast::Builtins::strftime
Requires:       yast2-ruby-bindings >= 3.1.38

BuildArch:      noarch

%description
A YaST2 module to read the systemd journal in a convenient and
user-friendly way.

%prep
%setup -q

%check
%yast_check

%install
%yast_install
%yast_metainfo

%files
%{yast_clientdir}
%{yast_libdir}
%{yast_desktopdir}
%{yast_metainfodir}
%{yast_icondir}
%doc COPYING
%doc README.md

%build
