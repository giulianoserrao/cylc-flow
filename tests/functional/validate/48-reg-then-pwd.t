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
# Test validation order, installed suites before current working directory.
. "$(dirname "$0")/test_header"
set_test_number 2

SUITE_NAME="${CYLC_TEST_REG_BASE}/${TEST_SOURCE_DIR_BASE}/${TEST_NAME_BASE}"

mkdir -p 'good' "${SUITE_NAME}"
cat >'good/flow.cylc' <<'__FLOW_CONFIG__'
[scheduling]
    [[graph]]
        R1 = t0
[runtime]
    [[t0]]
        script = true
__FLOW_CONFIG__
cat >"${SUITE_NAME}/flow.cylc" <<'__FLOW_CONFIG__'
[scheduling]
    [[graph]]
        R1 = t0
[runtime]
    [[t0]]
        scribble = true
__FLOW_CONFIG__

# This should validate bad suite under current directory
run_fail "${TEST_NAME_BASE}" cylc validate "${SUITE_NAME}"

# This should validate installed good suite
cylc install --flow-name="${SUITE_NAME}" -C "${PWD}/good" --no-run-name
run_ok "${TEST_NAME_BASE}" cylc validate "${SUITE_NAME}"

purge
exit
