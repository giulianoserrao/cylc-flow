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
# Test cylc show for a clock triggered task
. "$(dirname "$0")/test_header"
#-------------------------------------------------------------------------------
set_test_number 3
#-------------------------------------------------------------------------------
install_suite "${TEST_NAME_BASE}" clock-triggered-non-utc-mode
#-------------------------------------------------------------------------------
cd "${SUITE_RUN_DIR}" || exit 1
TEST_SHOW_OUTPUT_PATH="$PWD/${TEST_NAME_BASE}-show.stdout"
TZ_OFFSET_EXTENDED=$(date +%:z | sed "/^%/d")
if [[ -z "${TZ_OFFSET_EXTENDED}" ]]; then
    skip 3 "'date' command doesn't support '%:z'"
    exit 0
fi
TZ_OFFSET_BASIC=$(date +%z | sed "/^%/d")
if [[ "${TZ_OFFSET_EXTENDED}" == "+00:00" ]]; then
    TZ_OFFSET_EXTENDED=Z
    TZ_OFFSET_BASIC=Z
fi
#-------------------------------------------------------------------------------
TEST_NAME="${TEST_NAME_BASE}-validate"
run_ok "${TEST_NAME}" cylc validate \
    --set="TEST_SHOW_OUTPUT_PATH='$TEST_SHOW_OUTPUT_PATH'" \
    --set="TZ_OFFSET_BASIC='$TZ_OFFSET_BASIC'" "${SUITE_NAME}"
#-------------------------------------------------------------------------------
sed "s/\$TZ_OFFSET_BASIC/$TZ_OFFSET_BASIC/g" reference-untz.log >reference.log
TEST_NAME="${TEST_NAME_BASE}-run"
suite_run_ok "${TEST_NAME}" cylc play --reference-test --debug --no-detach \
    --set="TEST_SHOW_OUTPUT_PATH='$TEST_SHOW_OUTPUT_PATH'" \
    --set="TZ_OFFSET_BASIC='$TZ_OFFSET_BASIC'" "${SUITE_NAME}"
#-------------------------------------------------------------------------------
TEST_NAME=${TEST_NAME_BASE}-show
contains_ok "${TEST_NAME}.stdout" <<__SHOW_OUTPUT__
title: (not given)
description: (not given)
URL: (not given)

prerequisites (- => not satisfied):
  + woo.20140808T0900$TZ_OFFSET_BASIC succeeded

outputs (- => not completed):
  - foo.20140808T0900$TZ_OFFSET_BASIC expired
  + foo.20140808T0900$TZ_OFFSET_BASIC submitted
  - foo.20140808T0900$TZ_OFFSET_BASIC submit-failed
  + foo.20140808T0900$TZ_OFFSET_BASIC started
  - foo.20140808T0900$TZ_OFFSET_BASIC succeeded
  - foo.20140808T0900$TZ_OFFSET_BASIC failed

other (- => not satisfied):
  + Clock trigger time reached
  o Triggers at ... 2014-08-08T09:05:00$TZ_OFFSET_EXTENDED
__SHOW_OUTPUT__
#-------------------------------------------------------------------------------
purge
