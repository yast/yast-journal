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

require 'systemd_journal/entry'
require 'delegate'

module SystemdJournal
  # Presenter for Entry adding useful methods for the dialogs
  class EntryPresenter < SimpleDelegator

    # FIXME: using %b is not i18n-friendly
    TIME_FORMAT = "%b %d %H:%M:%S"

    def initialize(entry)
      __setobj__(entry)
    end

    # Original entry
    def entry
      __getobj__
    end

    # Source of the entry to be displayed on listings.
    #
    # Mimics the default journalctl output.
    def source
      if process_name
        "#{process_name}[#{pid}]"
      else
        syslog_id
      end
    end

    # User readable representation of the timestamp
    def formatted_time
      timestamp.strftime(TIME_FORMAT)
    end
  end
end


