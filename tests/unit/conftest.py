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
"""Standard pytest fixtures for unit tests."""
from cylc.flow.data_store_mgr import DataStoreMgr
import pytest
from shutil import rmtree
from unittest.mock import create_autospec, Mock

from cylc.flow.cfgspec.globalcfg import SPEC
from cylc.flow.cycling.loader import (
    ISO8601_CYCLING_TYPE,
    INTEGER_CYCLING_TYPE
)
from cylc.flow.parsec.config import ParsecConfig
from cylc.flow.scheduler import Scheduler
from cylc.flow.xtrigger_mgr import XtriggerManager


@pytest.fixture
def cycling_mode(monkeypatch):
    """Set the Cylc cycling mode and return its value."""
    def _cycling_mode(integer=True):
        mode = INTEGER_CYCLING_TYPE if integer else ISO8601_CYCLING_TYPE

        class _DefaultCycler:
            TYPE = mode
        monkeypatch.setattr(
            'cylc.flow.cycling.loader.DefaultCycler', _DefaultCycler)
        return mode
    return _cycling_mode


@pytest.fixture
def mock_glbl_cfg(tmp_path, monkeypatch):
    """A Pytest fixture for fiddling global config values.

    * Hacks the specified `glbl_cfg` object.
    * Can be called multiple times within a test function.

    Args:
        pypath (str):
            The python-like path to the global configuation object you want
            to fiddle.
            E.G. if you want to hack the `glbl_cfg` in
            `cylc.flow.scheduler` you would provide
            `cylc.flow.scheduler.glbl_cfg`
        global_config (str):
            The globlal configuration as a multi-line string.

    Example:
        Change the value of `UTC mode` in the global config as seen from
        `the scheduler` module.

        def test_something(mock_glbl_cfg):
            mock_glbl_cfg(
                'cylc.flow.scheduler.glbl_cfg',
                '''
                    [scheduler]
                        UTC mode = True
                '''
            )

    """
    # TODO: modify Parsec so we can use StringIO rather than a temp file.
    def _mock(pypath, global_config):
        nonlocal tmp_path, monkeypatch
        global_config_path = tmp_path / 'global.cylc'
        global_config_path.write_text(global_config)
        glbl_cfg = ParsecConfig(SPEC)
        glbl_cfg.loadcfg(global_config_path)

        def _inner(cached=False):
            nonlocal glbl_cfg
            return glbl_cfg

        monkeypatch.setattr(pypath, _inner)

    yield _mock
    rmtree(tmp_path)


@pytest.fixture
def xtrigger_mgr() -> XtriggerManager:
    """A fixture to build an XtriggerManager which uses a mocked proc_pool,
    and uses a mocked broadcast_mgr."""
    return XtriggerManager(
        suite="sample_suite",
        user="john-foo",
        proc_pool=Mock(put_command=lambda *a, **k: True),
        broadcast_mgr=Mock(put_broadcast=lambda *a, **k: True),
        data_store_mgr=DataStoreMgr(create_autospec(Scheduler))
    )
