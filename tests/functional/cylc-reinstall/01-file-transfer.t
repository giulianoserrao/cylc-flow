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
# Test workflow re-installation file transfer
. "$(dirname "$0")/test_header"
if ! command -v 'tree' >'/dev/null'; then
    skip_all '"tree" command not available'
fi
set_test_number 14

# Test cylc install copies files to run dir successfully.
TEST_NAME="${TEST_NAME_BASE}-basic"
make_rnd_suite
pushd "${RND_SUITE_SOURCE}" || exit 1
mkdir .git .svn dir1 dir2-be-removed
touch .git/file1 .svn/file1 dir1/file1 dir2-be-removed/file1 file1 file2
run_ok "${TEST_NAME}" cylc install

tree_excludes='*.log|01-file-transfer*|rose-suite*.conf|opt'

tree -a -v -I "${tree_excludes}" --charset=ascii --noreport "${RND_SUITE_RUNDIR}/run1" > '01-file-transfer-basic-tree.out'

cmp_ok '01-file-transfer-basic-tree.out'  <<__OUT__
${RND_SUITE_RUNDIR}/run1
|-- .service
|-- dir1
|   \`-- file1
|-- dir2-be-removed
|   \`-- file1
|-- file1
|-- file2
|-- flow.cylc
\`-- log
    \`-- install
__OUT__
contains_ok "${TEST_NAME}.stdout" <<__OUT__
INSTALLED $RND_SUITE_NAME from ${RND_SUITE_SOURCE} -> ${RND_SUITE_RUNDIR}/run1
__OUT__
run_ok "${TEST_NAME}" cylc install
mkdir new_dir
touch new_dir/new_file1 new_dir/new_file2
rm -rf dir2-be-removed file2
run_ok "${TEST_NAME}-reinstall" cylc reinstall "${RND_SUITE_NAME}/run2"
REINSTALL_LOG="$(find "${RND_SUITE_RUNDIR}/run2/log/install" -type f -name '*reinstall.log')"
grep_ok "deleting dir2-be-removed/file1
         deleting file2
         new_dir/
         new_dir/new_file1
         new_dir/new_file2" "${REINSTALL_LOG}"

tree -a -v -I "${tree_excludes}" --charset=ascii --noreport "${RND_SUITE_RUNDIR}/run2" > 'after-reinstall-run2-tree.out'
cmp_ok 'after-reinstall-run2-tree.out'  <<__OUT__
${RND_SUITE_RUNDIR}/run2
|-- .service
|-- dir1
|   \`-- file1
|-- file1
|-- flow.cylc
|-- log
|   \`-- install
\`-- new_dir
    |-- new_file1
    \`-- new_file2
__OUT__
contains_ok "${TEST_NAME}-reinstall.stdout" <<__OUT__
REINSTALLED $RND_SUITE_NAME/run2 from ${RND_SUITE_SOURCE} -> ${RND_SUITE_RUNDIR}/run2
__OUT__

# Test cylc reinstall affects only named run, i.e. run1 should be unaffected in this case
tree -a -v -I "${tree_excludes}" --charset=ascii --noreport "${RND_SUITE_RUNDIR}/run1" > 'after-reinstall-run1-tree.out'
cmp_ok 'after-reinstall-run1-tree.out' '01-file-transfer-basic-tree.out'
popd || exit 1
purge_rnd_suite


# Test cylc reinstall creates flow.cylc given suite.rc.
TEST_NAME="${TEST_NAME_BASE}-reinstall-creates-flow.cylc-given-suite.rc"
make_rnd_suite
pushd "${RND_SUITE_SOURCE}" || exit 1
rm -f flow.cylc
touch suite.rc
run_ok "${TEST_NAME}-install" cylc install --no-run-name --flow-name="${RND_SUITE_NAME}"
rm -f "${RND_SUITE_RUNDIR}/flow.cylc"
exists_fail "${RND_SUITE_RUNDIR}/flow.cylc"
run_ok "${TEST_NAME}-reinstall" cylc reinstall "${RND_SUITE_NAME}"
exists_ok "${RND_SUITE_RUNDIR}/flow.cylc"
exists_fail "${RND_SUITE_SOURCE}/flow.cylc"
popd || exit 1
purge_rnd_suite

exit
