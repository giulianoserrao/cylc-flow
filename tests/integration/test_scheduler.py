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

import asyncio
import pytest
from typing import Any, TYPE_CHECKING

if TYPE_CHECKING:
    from cylc.flow.scheduler import Scheduler

Fixture = Any


@pytest.mark.asyncio
async def test_is_paused_after_stop(
        one_conf: Fixture, flow: Fixture, scheduler: Fixture, run: Fixture,
        db_select: Fixture):
    """Test the paused status is unset on normal shutdown."""
    reg: str = flow(one_conf)
    schd: 'Scheduler' = scheduler(reg, paused_start=True)
    # Run
    async with run(schd):
        assert not schd.is_restart
        assert schd.is_paused
    # Stopped
    assert ('is_paused', '1') not in db_select(schd, 'suite_params')
    # Restart
    schd = scheduler(reg, paused_start=None)
    async with run(schd):
        assert schd.is_restart
        assert not schd.is_paused


@pytest.mark.asyncio
async def test_is_paused_after_crash(
        one_conf: Fixture, flow: Fixture, scheduler: Fixture, run: Fixture,
        db_select: Fixture):
    """Test the paused status is not unset for an interrupted workflow."""
    reg: str = flow(one_conf)
    schd: 'Scheduler' = scheduler(reg, paused_start=True)

    def ctrl_c():
        raise asyncio.CancelledError("Mock keyboard interrupt")
    # Patch this part of the main loop
    _schd_suite_shutdown = schd.suite_shutdown
    schd.suite_shutdown = ctrl_c

    # Run
    with pytest.raises(asyncio.CancelledError) as exc:
        async with run(schd):
            assert not schd.is_restart
            assert schd.is_paused
        assert "Mock keyboard interrupt" in str(exc.value)
    # Stopped
    assert ('is_paused', '1') in db_select(schd, 'suite_params')
    # Reset patched method
    schd.suite_shutdown = _schd_suite_shutdown
    # Restart
    schd = scheduler(reg, paused_start=None)
    async with run(schd):
        assert schd.is_restart
        assert schd.is_paused


@pytest.mark.asyncio
async def test_resume_does_not_release_tasks(one: Fixture, run: Fixture):
    """Test that resuming a workflow does not release any held tasks."""
    schd: 'Scheduler' = one
    async with run(schd):
        assert schd.is_paused
        itasks = schd.pool.get_all_tasks()
        assert len(itasks) == 1
        itask = itasks[0]
        assert not itask.state.is_held

        schd.command_hold('*')
        schd.resume_workflow()
        assert not schd.is_paused
        assert itask.state.is_held
