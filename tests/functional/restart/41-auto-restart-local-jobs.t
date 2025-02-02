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
export REQUIRE_PLATFORM='loc:remote fs:shared runner:background'
. "$(dirname "$0")/test_header"
# shellcheck disable=SC2153
export CYLC_TEST_HOST2="${CYLC_TEST_HOST}"
export CYLC_TEST_HOST1="${HOSTNAME}"
if ${CYLC_TEST_DEBUG:-false}; then ERR=2; else ERR=1; fi
set_test_number 12
#-------------------------------------------------------------------------------
BASE_GLOBAL_CONFIG="
[scheduler]
    [[main loop]]
        plugins = health check, auto restart
        [[[auto restart]]]
            interval = PT2S
    [[events]]
        abort on inactivity = True
        abort on timeout = True
        inactivity = PT2M
        timeout = PT2M
"

init_suite "${TEST_NAME_BASE}" <<< '
[scheduling]
    [[graph]]
        R1 = foo => bar
[runtime]
    [[foo]]
        # we will trigger bar manually later
        script = sleep 15; false
    [[bar]]
        script = sleep 60
'
cd "${SUITE_RUN_DIR}" || exit 1

create_test_global_config '' "
${BASE_GLOBAL_CONFIG}
[scheduler]
    [[run hosts]]
        available = ${CYLC_TEST_HOST1}
"

cylc play "${SUITE_NAME}"
#-------------------------------------------------------------------------------
# auto stop-restart - normal mode:
#     ensure the suite WAITS for local jobs to complete before restarting
TEST_NAME="${TEST_NAME_BASE}-normal-mode"

cylc suite-state "${SUITE_NAME}" --task='foo' --status='running' --point=1 \
    --interval=1 --max-polls=20 >& $ERR

create_test_global_config '' "
${BASE_GLOBAL_CONFIG}
[scheduler]
    [[run hosts]]
        available = ${CYLC_TEST_HOST1}, ${CYLC_TEST_HOST2}
        condemned = ${CYLC_TEST_HOST1}
"

FILE="$(cylc cat-log "${SUITE_NAME}" -m p |xargs readlink -f)"
log_scan "${TEST_NAME}-stop" "${FILE}" 40 1 \
    'The Cylc suite host will soon become un-available' \
    'Waiting for jobs running on localhost to complete' \
    'Waiting for jobs running on localhost to complete' \
    'Suite shutting down - REQUEST(NOW-NOW)' \
    "Attempting to restart on \"${CYLC_TEST_HOST2}\"" \
    "Suite now running on \"${CYLC_TEST_HOST2}\"" \

# we shouldn't have any orphaned tasks because we should
# have waited for them to complete
grep_fail 'orphaned task' "${FILE}"

poll_suite_restart
#-------------------------------------------------------------------------------
# auto stop-restart - force mode:
#     ensure the suite DOESN'T WAIT for local jobs to complete before stopping
TEST_NAME="${TEST_NAME_BASE}-force-mode"

cylc trigger "${SUITE_NAME}" bar.1
cylc suite-state "${SUITE_NAME}" --task='bar' --status='running' --point=1 \
    --interval=1 --max-polls=20 >& $ERR

create_test_global_config '' "
${BASE_GLOBAL_CONFIG}
[scheduler]
    [[run hosts]]
        available = ${CYLC_TEST_HOST1}, ${CYLC_TEST_HOST2}
        condemned = ${CYLC_TEST_HOST2}!
"

FILE="$(cylc cat-log "${SUITE_NAME}" -m p |xargs readlink -f)"
log_scan "${TEST_NAME}-stop" "${FILE}" 40 1 \
    'The Cylc suite host will soon become un-available' \
    'This suite will be shutdown as the suite host is unable to continue' \
    'Suite shutting down - REQUEST(NOW)' \
    'Orphaned task jobs:' \
    '* bar.1 (running)'

cylc stop "${SUITE_NAME}" --now --now 2>/dev/null || true
poll_suite_stopped
sleep 1
purge
exit
