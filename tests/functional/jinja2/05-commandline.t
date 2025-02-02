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
# jinja2 command line variables test
. "$(dirname "$0")/test_header"
#-------------------------------------------------------------------------------
set_test_number 3
#-------------------------------------------------------------------------------
install_suite "${TEST_NAME_BASE}" commandline-set
#-------------------------------------------------------------------------------
TEST_NAME=${TEST_NAME_BASE}-validate1
run_ok "${TEST_NAME}" cylc validate --set="TASKNAME='foo'" --set="STEP='2'" "${SUITE_NAME}"
#-------------------------------------------------------------------------------
TEST_NAME=${TEST_NAME_BASE}-validate2
run_ok "${TEST_NAME}" cylc validate \
    --set-file="${TEST_DIR}/${SUITE_NAME}/vars.txt" "${SUITE_NAME}"
#-------------------------------------------------------------------------------
TEST_NAME="${TEST_NAME_BASE}-run"
suite_run_ok "${TEST_NAME}" cylc play --no-detach --reference-test \
    --set-file="${TEST_DIR}/${SUITE_NAME}/vars.txt" "${SUITE_NAME}"
#-------------------------------------------------------------------------------
purge
