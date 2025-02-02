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
# play a game of Cylc suite ping pong bouncing a suite back and forth between
# two servers by condemning them in turn in order to see if anything breaks
export REQUIRE_PLATFORM='loc:remote fs:shared runner:background'
. "$(dirname "$0")/test_header"
export CLOWNS="${CYLC_TEST_HOST}"
export JOKERS="${HOSTNAME}"

BASE_GLOBAL_CONFIG='
[scheduler]
    [[main loop]]
        plugins = health check, auto restart
        [[[auto restart]]]
            interval = PT5S
    [[events]]
        abort on inactivity = True
        abort on timeout = True
        inactivity = PT2M
        timeout = PT2M
'

init_suite "${TEST_NAME_BASE}" <<< '
[scheduling]
    initial cycle point = 2000
    final cycle point = 9999  # test cylc/cylc-flow/issues/2799
    [[graph]]
        P1Y = foo[-P1Y] => foo
[runtime]
    [[foo]]
        script = sleep 5
'
cd "${SUITE_RUN_DIR}" || exit 1
stuck_in_the_middle() {
    # swap the condemned host forcing the suite to jump ship
    local temp="${JOKERS}"
    JOKERS="${CLOWNS}"; CLOWNS="${temp}"
    create_test_global_config '' "
    ${BASE_GLOBAL_CONFIG}
    [scheduler]
        [[run hosts]]
            available = ${JOKERS}, ${CLOWNS}
            condemned = ${CLOWNS}
    "
}

kill_suite() {
    cylc stop --now --now --max-polls=10 --interval=2 "${SUITE_NAME}" 2>'/dev/null'
    purge
}

log_scan2() {
    NO_TESTS="$(( NO_TESTS - $# + 4 ))"
    if ! log_scan "$@"; then
        skip $NO_TESTS  # skip remaining tests
        kill_suite
        exit 1
    fi
}

EARS=5  # number of times to bounce the suite between hosts
NO_TESTS="$(( EARS * 5 + 1 ))"
set_test_number "${NO_TESTS}"

run_ok "${TEST_NAME_BASE}-validate" cylc validate "${SUITE_NAME}"

# run the suite
stuck_in_the_middle
cylc play "${SUITE_NAME}" --host="${JOKERS}" --abort-if-any-task-fails
poll_suite_running
sleep 1

# get the log file
FILE=$(cylc cat-log "${SUITE_NAME}" -m p |xargs readlink -f)
#-------------------------------------------------------------------------------
for ear in $(seq 1 "${EARS}"); do
    stuck_in_the_middle  # swap the condemned host

    # test the shutdown procedure
    log_scan2 "${TEST_NAME_BASE}-${ear}-stop" "${FILE}" 40 1 \
        'The Cylc suite host will soon become un-available' \
        'Suite shutting down - REQUEST(NOW-NOW)' \
        "Attempting to restart on \"${JOKERS}\"" \
        "Suite now running on \"${JOKERS}\"" \

    poll_suite_restart

    # test the restart procedure
    FILE=$(cylc cat-log "${SUITE_NAME}" -m p |xargs readlink -f)
    log_scan2 "${TEST_NAME_BASE}-${ear}-restart" "${FILE}" 20 1 \
        "Suite server: url=tcp://$(get_fqdn "${JOKERS}")"
    sleep 2
done

kill_suite

exit
