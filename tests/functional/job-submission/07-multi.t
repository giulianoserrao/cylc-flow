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
# Test job submission, multiple jobs per host.
export REQUIRE_PLATFORM='loc:remote'
. "$(dirname "$0")/test_header"
set_test_number 3

install_suite "${TEST_NAME_BASE}" "${TEST_NAME_BASE}"

run_ok "${TEST_NAME_BASE}-validate" \
    cylc validate "${SUITE_NAME}" -s "CYLC_TEST_PLATFORM='${CYLC_TEST_PLATFORM}'"
suite_run_ok "${TEST_NAME_BASE}-run" \
    cylc play --debug --no-detach --reference-test \
        -s "CYLC_TEST_PLATFORM='${CYLC_TEST_PLATFORM}'" \
    "${SUITE_NAME}"

RUN_DIR="$RUN_DIR/${SUITE_NAME}"
LOG="${RUN_DIR}/log/suite/log"
sed -n 's/^.*\(cylc jobs-submit\)/\1/p' "${LOG}" | sort -u >'edited-suite-log'

PATHOPTS="--path=/bin --path=/usr/bin --path=/usr/local/bin --path=/sbin --path=/usr/sbin --path=/usr/local/sbin"
sort >'edited-suite-log-ref' <<__LOG__
cylc jobs-submit --debug --utc-mode $PATHOPTS -- '\$HOME/cylc-run/${SUITE_NAME}/log/job' 20200101T0000Z/t0/01 20200101T0000Z/t1/01 20200101T0000Z/t2/01 20200101T0000Z/t3/01
cylc jobs-submit --debug --utc-mode $PATHOPTS -- '\$HOME/cylc-run/${SUITE_NAME}/log/job' 20210101T0000Z/t0/01 20210101T0000Z/t1/01 20210101T0000Z/t2/01 20210101T0000Z/t3/01
cylc jobs-submit --debug --utc-mode $PATHOPTS -- '\$HOME/cylc-run/${SUITE_NAME}/log/job' 20220101T0000Z/t0/01 20220101T0000Z/t1/01 20220101T0000Z/t2/01 20220101T0000Z/t3/01
cylc jobs-submit --debug --utc-mode $PATHOPTS -- '\$HOME/cylc-run/${SUITE_NAME}/log/job' 20230101T0000Z/t0/01 20230101T0000Z/t1/01 20230101T0000Z/t2/01 20230101T0000Z/t3/01
cylc jobs-submit --debug --utc-mode $PATHOPTS -- '\$HOME/cylc-run/${SUITE_NAME}/log/job' 20240101T0000Z/t0/01 20240101T0000Z/t1/01 20240101T0000Z/t2/01 20240101T0000Z/t3/01
cylc jobs-submit --debug --utc-mode $PATHOPTS -- '\$HOME/cylc-run/${SUITE_NAME}/log/job' 20250101T0000Z/t0/01 20250101T0000Z/t1/01 20250101T0000Z/t2/01 20250101T0000Z/t3/01
cylc jobs-submit --debug --utc-mode --remote-mode $PATHOPTS -- '\$HOME/cylc-run/${SUITE_NAME}/log/job' 20200101T0000Z/t4/01 20200101T0000Z/t5/01 20200101T0000Z/t6/01
cylc jobs-submit --debug --utc-mode --remote-mode $PATHOPTS -- '\$HOME/cylc-run/${SUITE_NAME}/log/job' 20210101T0000Z/t4/01 20210101T0000Z/t5/01 20210101T0000Z/t6/01
cylc jobs-submit --debug --utc-mode --remote-mode $PATHOPTS -- '\$HOME/cylc-run/${SUITE_NAME}/log/job' 20220101T0000Z/t4/01 20220101T0000Z/t5/01 20220101T0000Z/t6/01
cylc jobs-submit --debug --utc-mode --remote-mode $PATHOPTS -- '\$HOME/cylc-run/${SUITE_NAME}/log/job' 20230101T0000Z/t4/01 20230101T0000Z/t5/01 20230101T0000Z/t6/01
cylc jobs-submit --debug --utc-mode --remote-mode $PATHOPTS -- '\$HOME/cylc-run/${SUITE_NAME}/log/job' 20240101T0000Z/t4/01 20240101T0000Z/t5/01 20240101T0000Z/t6/01
cylc jobs-submit --debug --utc-mode --remote-mode $PATHOPTS -- '\$HOME/cylc-run/${SUITE_NAME}/log/job' 20250101T0000Z/t4/01 20250101T0000Z/t5/01 20250101T0000Z/t6/01
__LOG__
cmp_ok 'edited-suite-log' 'edited-suite-log-ref'

purge
exit
