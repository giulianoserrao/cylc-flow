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
# Test validating platforms in suite.
. "$(dirname "$0")/test_header"

set_test_number 1

TEST_NAME="${TEST_NAME_BASE}-val"

create_test_global_config "" "
    [platforms]
        [[localhost, lewis]]
            hosts = localhost
            install target = localhost
"

cat >'flow.cylc' <<'__FLOW_CONFIG__'
[meta]
    title = "Test validation of simple multiple inheritance"

    description = """Bug identified at 5.1.1-314-g4960684."""

[scheduling]
[[graph]]
R1 = """foo"""
[runtime]
[[foo]]
platform=lewis


__FLOW_CONFIG__

run_ok "${TEST_NAME}" cylc validate flow.cylc
