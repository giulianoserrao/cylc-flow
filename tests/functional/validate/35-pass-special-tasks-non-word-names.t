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
# Test validation of special tasks names with non-word characters
. "$(dirname "$0")/test_header"
set_test_number 1
cat >'flow.cylc' <<'__FLOW_CONFIG__'
[scheduling]
    initial cycle point = 20200202
    final cycle point = 20300303
    [[special tasks]]
        clock-trigger = t-1, t+1, t%1, t@1
    [[graph]]
        P1D = """
            t-1
            t+1
            t%1
            t@1
        """

[runtime]
    [[t-1, t+1, t%1, t@1]]
        script = true
__FLOW_CONFIG__
run_ok "${TEST_NAME_BASE}" cylc validate "${PWD}/flow.cylc"
exit
