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
. "$(dirname "$0")/test_header"
set_test_number 8
install_suite "${TEST_NAME_BASE}" "${TEST_NAME_BASE}"

test_dump() {
    local TEST_NAME="$1"
    run_ok "${TEST_NAME}" python3 - "$@" <<'__PYTHON__'
import ast
import sys

data = ast.literal_eval(open(sys.argv[1]).read())

keys = list(
    f"{task['name']}.{task['cyclePoint']}"
    for task in data['taskProxies']
)
if keys != ["t1.2031", "t2.2031"]:
    sys.exit(keys)
for datum in data['tasks']:
    assert isinstance(datum['meanElapsedTime'], float)
__PYTHON__
}
cd "${SUITE_RUN_DIR}" || exit 1
run_ok "${TEST_NAME_BASE}-validate" cylc validate "${SUITE_NAME}"

RUND="${RUN_DIR}/${SUITE_NAME}"
suite_run_ok "${TEST_NAME_BASE}-run" \
    cylc play "${SUITE_NAME}" --debug --no-detach --stopcp=2020
suite_run_ok "${TEST_NAME_BASE}-restart-1" \
    cylc play "${SUITE_NAME}" --stopcp=2028 --debug --no-detach
sed -n '/LOADING task run times/,+2{s/^.* INFO - //;s/[0-9]\(,\|$\)/%d\1/g;p}' \
    "${RUND}/log/suite/log" >'restart-1.out'
contains_ok "restart-1.out" <<'__OUT__'
LOADING task run times
+ t2: %d,%d,%d,%d,%d
+ t1: %d,%d,%d,%d,%d
__OUT__
suite_run_ok "${TEST_NAME_BASE}-restart-2" \
    cylc play "${SUITE_NAME}" --stopcp=2030 --debug --no-detach
sed -n '/LOADING task run times/,+2{s/^.* INFO - //;s/[0-9]\(,\|$\)/%d\1/g;p}' \
    "${RUND}/log/suite/log" >'restart-2.out'
contains_ok 'restart-2.out' <<'__OUT__'
LOADING task run times
+ t2: %d,%d,%d,%d,%d,%d,%d,%d,%d,%d
+ t1: %d,%d,%d,%d,%d,%d,%d,%d,%d,%d
__OUT__
suite_run_ok "${TEST_NAME_BASE}-restart-3" \
    cylc play "${SUITE_NAME}" --hold-after=1900
# allow the task pool to settle before requesting a dump
cylc suite-state "${SUITE_NAME}" \
    --task=t1 \
    --point=2031 \
    --status=running \
    --interval=1 \
    --max-polls=10 1>'/dev/null' 2>&1
cylc dump -r "${SUITE_NAME}" >'cylc-dump.out'

test_dump 'cylc-dump.out'

cylc stop --max-polls=10 --interval=2 "${SUITE_NAME}"
purge
exit
