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

#------------------------------------------------------------------------------
# Test workflow reinstallation expected failures
. "$(dirname "$0")/test_header"
set_test_number 26

# Test fails is there is a nested run directory structure in the run directory to be reinstalled

TEST_NAME="${TEST_NAME_BASE}-nested-rundir-forbidden-reinstall"
make_rnd_suite
run_ok "${TEST_NAME}-install" cylc install -C "${RND_SUITE_SOURCE}" --flow-name="${RND_SUITE_NAME}"
mkdir "${RND_SUITE_RUNDIR}/run1/nested_run_dir"
touch "${RND_SUITE_RUNDIR}/run1/nested_run_dir/flow.cylc"
run_fail "${TEST_NAME}-reinstall-nested-run-dir" cylc reinstall "${RND_SUITE_NAME}"
contains_ok "${TEST_NAME}-reinstall-nested-run-dir.stderr" <<__ERR__
WorkflowFilesError: Nested run directories not allowed - cannot install workflow name "${RND_SUITE_NAME}" as "${RND_SUITE_RUNDIR}/run1" is already a valid run directory.
__ERR__
purge_rnd_suite

# Test fail no suite source dir

TEST_NAME="${TEST_NAME_BASE}-reinstall-no-run-dir"
make_rnd_suite
run_ok "${TEST_NAME}-install" cylc install -C "${RND_SUITE_SOURCE}" --flow-name="${RND_SUITE_NAME}" --no-run-name
rm -rf "${RND_SUITE_RUNDIR}"
run_fail "${TEST_NAME}-reinstall" cylc reinstall "${RND_SUITE_NAME}" 
contains_ok "${TEST_NAME}-reinstall.stderr" <<__ERR__
WorkflowFilesError: "${RND_SUITE_NAME}" is not an installed workflow.
__ERR__
purge_rnd_suite

# Test fail no suite source dir

TEST_NAME="${TEST_NAME_BASE}-reinstall-no-source-dir"
make_rnd_suite
run_ok "${TEST_NAME}-install" cylc install -C "${RND_SUITE_SOURCE}" --flow-name="${RND_SUITE_NAME}" --no-run-name
rm -rf "${RND_SUITE_SOURCE}"
run_fail "${TEST_NAME}-reinstall" cylc reinstall "${RND_SUITE_NAME}"  
contains_ok "${TEST_NAME}-reinstall.stderr" <<__ERR__
WorkflowFilesError: Workflow source dir is not accessible: "${RND_SUITE_SOURCE}".
Restore the source or modify the "${RND_SUITE_RUNDIR}/_cylc-install/source" symlink to continue.
__ERR__
purge_rnd_suite

# Test fail no flow.cylc or suite.rc file

TEST_NAME="${TEST_NAME_BASE}-no-flow-file"
make_rnd_suite
run_ok "${TEST_NAME}-install" cylc install -C "${RND_SUITE_SOURCE}" --flow-name="${RND_SUITE_NAME}" --no-run-name
rm -f "${RND_SUITE_SOURCE}/flow.cylc"
run_fail "${TEST_NAME}" cylc reinstall "${RND_SUITE_NAME}"
contains_ok "${TEST_NAME}.stderr" <<__ERR__
WorkflowFilesError: no flow.cylc or suite.rc in ${RND_SUITE_SOURCE}
__ERR__
purge_rnd_suite

# Test source dir can not contain '_cylc-install, log, share, work' dirs for cylc reinstall

for DIR in 'work' 'share' 'log' '_cylc-install'; do
    TEST_NAME="${TEST_NAME_BASE}-${DIR}-forbidden-in-source"
    make_rnd_suite
    pushd "${RND_SUITE_SOURCE}" || exit 1
    cylc install --no-run-name --flow-name="${RND_SUITE_NAME}"
    mkdir ${DIR}
    run_fail "${TEST_NAME}" cylc reinstall "${RND_SUITE_NAME}"
    contains_ok "${TEST_NAME}.stderr" <<__ERR__
WorkflowFilesError: ${RND_SUITE_NAME} installation failed. - ${DIR} exists in source directory.
__ERR__
    purge_rnd_suite
    popd || exit 1
done

# Test cylc reinstall (no args given) raises error when no source dir.
TEST_NAME="${TEST_NAME_BASE}-reinstall-no-source-rasies-error"
make_rnd_suite
pushd "${RND_SUITE_SOURCE}" || exit 1
run_ok "${TEST_NAME}-install" cylc install --no-run-name --flow-name="${RND_SUITE_NAME}"
pushd "${RND_SUITE_RUNDIR}" || exit 1
rm -rf "_cylc-install"
run_fail "${TEST_NAME}-reinstall" cylc reinstall
CWD=$(pwd -P)
contains_ok "${TEST_NAME}-reinstall.stderr" <<__ERR__
WorkflowFilesError: "${CWD}" is not a workflow run directory.
__ERR__
popd || exit 1
popd || exit 1
purge_rnd_suite

# Test cylc reinstall (args given) raises error when no source dir.
TEST_NAME="${TEST_NAME_BASE}-reinstall-no-source-rasies-error2"
make_rnd_suite
pushd "${RND_SUITE_SOURCE}" || exit 1
run_ok "${TEST_NAME}-install" cylc install --no-run-name --flow-name="${RND_SUITE_NAME}"
pushd "${RND_SUITE_RUNDIR}" || exit 1
rm -rf "_cylc-install"
run_fail "${TEST_NAME}-reinstall" cylc reinstall "$RND_SUITE_NAME"
contains_ok "${TEST_NAME}-reinstall.stderr" <<__ERR__
WorkflowFilesError: "${RND_SUITE_NAME}" was not installed with cylc install.
__ERR__
popd || exit 1
popd || exit 1
purge_rnd_suite

exit
