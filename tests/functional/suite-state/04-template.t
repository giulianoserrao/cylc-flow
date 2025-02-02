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
# Test cylc suite-state "template" option
. "$(dirname "$0")/test_header"
#-------------------------------------------------------------------------------
set_test_number 3
#-------------------------------------------------------------------------------
install_suite "${TEST_NAME_BASE}_ref" 'template_ref'
SUITE_NAME_REF="${SUITE_NAME}"
#-------------------------------------------------------------------------------
TEST_NAME="${TEST_NAME_BASE}-ref"
suite_run_ok "${TEST_NAME}" \
    cylc play --reference-test --debug --no-detach "${SUITE_NAME_REF}"
#-------------------------------------------------------------------------------
TEST_NAME="${TEST_NAME_BASE}-cli-template"
run_ok "${TEST_NAME}" \
    cylc suite-state "${SUITE_NAME_REF}" -p '20100101T0000Z' \
    --template=%Y --max-polls=1
#-------------------------------------------------------------------------------
install_suite "${TEST_NAME_BASE}" 'template'
TEST_NAME="${TEST_NAME_BASE}-runtime"
#-------------------------------------------------------------------------------
suite_run_ok "${TEST_NAME}" \
    cylc play --reference-test --debug --no-detach "${SUITE_NAME}" \
    --set="REF_SUITE='${SUITE_NAME_REF}'"
#-------------------------------------------------------------------------------
purge "${SUITE_NAME_REF}"
purge
#-------------------------------------------------------------------------------
exit 0
