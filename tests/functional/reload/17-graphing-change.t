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
# Test that removing a task from the graph works OK.
. "$(dirname "$0")/test_header"
#-------------------------------------------------------------------------------
set_test_number 12

grep_suite_log_n_times() {
    TEXT="$1"
    N_TIMES="$2"
    [[ $(grep -c "$TEXT" "${SUITE_RUN_DIR}/log/suite/log") == "$N_TIMES" ]]
}
#-------------------------------------------------------------------------------
# test reporting of added tasks

# install suite
install_suite "${TEST_NAME_BASE}" 'graphing-change'
LOG_FILE="${SUITE_RUN_DIR}/log/suite/log"

# start suite in paused mode
run_ok "${TEST_NAME_BASE}-add-run" cylc play --debug --pause "${SUITE_NAME}"

# change the flow.cylc file
cp "${TEST_SOURCE_DIR}/graphing-change/flow-1.cylc" \
    "${RUN_DIR}/${SUITE_NAME}/flow.cylc"

# reload suite
run_ok "${TEST_NAME_BASE}-add-reload" cylc reload "${SUITE_NAME}"
poll grep_suite_log_n_times 'Reload completed' 1

# check suite log
grep_ok "Added task: 'one'" "${LOG_FILE}"
#-------------------------------------------------------------------------------
# test reporting or removed tasks

# change the flow.cylc file
cp "${TEST_SOURCE_DIR}/graphing-change/flow.cylc" \
    "${RUN_DIR}/${SUITE_NAME}/flow.cylc"

# reload suite
run_ok "${TEST_NAME_BASE}-remove-reload" cylc reload "${SUITE_NAME}"
poll grep_suite_log_n_times 'Reload completed' 2

# check suite log
grep_ok "Removed task: 'one'" "${LOG_FILE}"
#-------------------------------------------------------------------------------
# test reporting of adding / removing / swapping tasks

# change the flow.cylc file
cp "${TEST_SOURCE_DIR}/graphing-change/flow-2.cylc" \
    "${RUN_DIR}/${SUITE_NAME}/flow.cylc"

cylc set-outputs "${SUITE_NAME}"  foo.1
cylc set-outputs "${SUITE_NAME}"  baz.1
# reload suite
run_ok "${TEST_NAME_BASE}-swap-reload" cylc reload "${SUITE_NAME}"
poll grep_suite_log_n_times 'Reload completed' 3

# check suite log
grep_ok "Added task: 'one'" "${LOG_FILE}"
grep_ok "Added task: 'add'" "${LOG_FILE}"
grep_ok "Added task: 'boo'" "${LOG_FILE}"
grep_ok "\\[bar.*\\].*task definition removed" "${LOG_FILE}"
grep_ok "\\[bol.*\\].*task definition removed" "${LOG_FILE}"

run_ok "${TEST_NAME_BASE}-stop" \
    cylc stop --max-polls=10 --interval=2 "${SUITE_NAME}"

purge
exit
