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
# Test remote initialisation - when remote init fails for an install target,
# check other platforms with same install target can be initialised.

export REQUIRE_PLATFORM='loc:remote fs:indep'
. "$(dirname "$0")/test_header"
#-------------------------------------------------------------------------------
set_test_number 5
create_test_global_config "" "
[platforms]
    [[ariel]]
        hosts = ${CYLC_TEST_HOST}
        install target = ${CYLC_TEST_INSTALL_TARGET}
    [[belle]]
        hosts = ${CYLC_TEST_HOST}
        install target = ${CYLC_TEST_INSTALL_TARGET}
        ssh command = garbage
    "

#-------------------------------------------------------------------------------
install_suite

run_ok "${TEST_NAME_BASE}-validate" cylc validate "${SUITE_NAME}"

suite_run_fail "${TEST_NAME_BASE}-run" \
    cylc play --debug --no-detach "${SUITE_NAME}"

NAME='select-task-jobs.out'
DB_FILE="${SUITE_RUN_DIR}/log/db"
sqlite3 "${DB_FILE}" \
    'SELECT name, submit_status, run_status, platform_name
     FROM task_jobs ORDER BY name' \
    >"${NAME}"
cmp_ok "${NAME}" <<__SELECT__
a|1||
b|1||
e|0|0|ariel
f|0|0|ariel
g|0|0|localhost
__SELECT__

grep_ok "WARNING - Suite stalled with unhandled failed tasks:" \
    "${TEST_NAME_BASE}-run.stderr"
grep_ok "* b.1 (submit-failed)
	* a.1 (submit-failed)" \
    "${TEST_NAME_BASE}-run.stderr"

purge
exit
