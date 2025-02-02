#!/usr/bin/env bash
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
# Test default runahead limit behaviour is still the same
. "$(dirname "$0")/test_header"
#-------------------------------------------------------------------------------
set_test_number 5
#-------------------------------------------------------------------------------
install_suite "${TEST_NAME_BASE}" default-future
#-------------------------------------------------------------------------------
TEST_NAME="${TEST_NAME_BASE}-validate"
run_ok "${TEST_NAME}" cylc validate -v --set="FUTURE_TRIGGER_START_POINT='T04'" \
    "${SUITE_NAME}"
#-------------------------------------------------------------------------------
TEST_NAME="${TEST_NAME_BASE}-run"
run_fail "${TEST_NAME}" cylc play --debug --no-detach --set="FUTURE_TRIGGER_START_POINT='T04'" \
    "${SUITE_NAME}"
#-------------------------------------------------------------------------------
TEST_NAME=${TEST_NAME_BASE}-max-cycle
DB="$RUN_DIR/${SUITE_NAME}/log/db"
run_ok "${TEST_NAME}" sqlite3 "${DB}" \
"select max(cycle) from task_states where name=='foo' and status=='failed'"
cmp_ok "${TEST_NAME}.stdout" <<< "20100101T0400Z"
# i.e. should have spawned 5 cycle points from initial T00 (wibble not spawned)
#-------------------------------------------------------------------------------
grep_ok 'Suite shutting down - Abort on suite inactivity is set' "${SUITE_RUN_DIR}/log/suite/log"
#-------------------------------------------------------------------------------
purge
