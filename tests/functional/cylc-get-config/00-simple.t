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
# Test cylc config
. "$(dirname "$0")/test_header"
#-------------------------------------------------------------------------------
set_test_number 19
#-------------------------------------------------------------------------------
init_suite "${TEST_NAME_BASE}" "${TEST_SOURCE_DIR}/${TEST_NAME_BASE}/flow.cylc"
#-------------------------------------------------------------------------------
TEST_NAME="${TEST_NAME_BASE}-all"
run_ok "${TEST_NAME}" cylc config "${SUITE_NAME}"
run_ok "${TEST_NAME}-validate" cylc validate --check-circular "${TEST_NAME}.stdout"
cmp_ok "${TEST_NAME}.stderr" <'/dev/null'
#-------------------------------------------------------------------------------
TEST_NAME="${TEST_NAME_BASE}-section1"
run_ok "${TEST_NAME}" cylc config --item=[scheduling] "${SUITE_NAME}"
cmp_ok "${TEST_NAME}.stdout" "$TEST_SOURCE_DIR/${TEST_NAME_BASE}/section1.stdout"
cmp_ok "${TEST_NAME}.stderr" - </dev/null
#-------------------------------------------------------------------------------
TEST_NAME="${TEST_NAME_BASE}-section1-section"
run_ok "${TEST_NAME}" cylc config --item=[scheduling][graph] "${SUITE_NAME}"
cmp_ok "${TEST_NAME}.stdout" - <<__OUT__
R1 = OPS:finish-all => VAR
__OUT__
cmp_ok "${TEST_NAME}.stderr" - </dev/null
#-------------------------------------------------------------------------------
TEST_NAME="${TEST_NAME_BASE}-section1-section-option"
run_ok "${TEST_NAME}" \
    cylc config --item=[scheduling][graph]R1 "${SUITE_NAME}"
cmp_ok "${TEST_NAME}.stdout" - <<__OUT__
OPS:finish-all => VAR
__OUT__
cmp_ok "${TEST_NAME}.stderr" - </dev/null
#-------------------------------------------------------------------------------
TEST_NAME="${TEST_NAME_BASE}-section2"
run_ok "${TEST_NAME}" cylc config --item=[runtime] "${SUITE_NAME}"
# Crude sorting to handle against change of dict order when new items added:
sort "${TEST_NAME}.stdout" > stdout.1
sort "$TEST_SOURCE_DIR/${TEST_NAME_BASE}/section2.stdout" > stdout.2
cmp_ok stdout.1 stdout.2
cmp_ok "${TEST_NAME}.stderr" - </dev/null
#-------------------------------------------------------------------------------
# Basic test that --print-hierarchy works
TEST_NAME="${TEST_NAME_BASE}-hierarchy"
run_ok "${TEST_NAME}-global" cylc config --print-hierarchy
run_ok "${TEST_NAME}-all" cylc config --print-hierarchy "${SUITE_NAME}"
# The two should be same with last line of latter removed
cmp_ok "${TEST_NAME}-global.stdout" <<< "$( sed '$d' "${TEST_NAME}-all.stdout" )"
# The last line should be the workflow run dir
sed '$!d' "${TEST_NAME}-all.stdout" > "flow_path.out"
cmp_ok "flow_path.out" <<< "${SUITE_RUN_DIR}/flow.cylc"

purge
exit
