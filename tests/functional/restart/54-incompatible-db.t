#!/bin/bash
# THIS FILE IS PART OF THE CYLC SUITE ENGINE.
# Copyright (C) NIWA & British Crown (Met Office) & Contributors.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# -----------------------------------------------------------------------------
# Test that restarting a Cylc 7 suite does not work due to database
# incompatibility, and that suitable error message is given

. "$(dirname "$0")/test_header"
set_test_number 3

install_suite
# install the cylc7 restart database
sqlite3 "${SUITE_RUN_DIR}/.service/db" < 'db.sqlite3'

run_ok "${TEST_NAME_BASE}-validate" cylc validate "${SUITE_NAME}"

TEST_NAME="${TEST_NAME_BASE}-restart-fail"
suite_run_fail "$TEST_NAME" cylc play "${SUITE_NAME}"

grep_ok 'Workflow database is incompatible' "${TEST_NAME}.stderr"

purge

# Note: The test for "trying to restart a suite without a database gives
# suitable error message" was removed with the change from cylc run/restart to
# cylc play, as if the database is not present it will simply do a cold start

exit
