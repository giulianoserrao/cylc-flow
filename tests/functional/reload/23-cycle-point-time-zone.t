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
#-------------------------------------------------------------------------------
# Test saving and loading of cycle point time zone to/from database on a run
# followed by a reload. Important for reloading a suite after a system
# time zone change.

. "$(dirname "$0")/test_header"

set_test_number 5

init_suite "${TEST_NAME_BASE}" << '__FLOW__'
[scheduler]
    UTC mode = False
    allow implicit tasks = True
[scheduling]
    initial cycle point = now
    [[graph]]
        R1 = foo
__FLOW__

run_ok "${TEST_NAME_BASE}-validate" cylc validate "${SUITE_NAME}"

# Set time zone to +01:00
export TZ=BST-1

suite_run_ok "${TEST_NAME_BASE}-run" cylc play "${SUITE_NAME}" --pause
poll_suite_running

# Simulate DST change
export TZ=UTC

run_ok "${TEST_NAME_BASE}-reload" cylc reload "${SUITE_NAME}"
poll_suite_running

cylc stop --now --now "${SUITE_NAME}"

log_scan "${TEST_NAME_BASE}-log-scan" "${SUITE_RUN_DIR}/log/suite/log" 1 0 \
    'LOADING suite parameters' \
    '+ cycle point time zone = +0100'

purge
