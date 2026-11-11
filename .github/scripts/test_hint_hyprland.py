#! /usr/bin/env python3
"""Regression test for expand_meta_data()'s Lua command-cache recovery.

hyprctl reports a Lua bind built from hl.dsp.exec_cmd only as an opaque
registry handle -- "__lua" on older builds, "HL.Dispatcher(exec_cmd)" on
0.57+ -- and keybinds_hint.sh dispatches whatever it finds there. The cache
hyde/binds.lua writes must therefore be able to rewrite both formats into a
real exec_cmd call; a combo the cache does not have instead falls back to
the bind's own action, dispatched through hyde.binds.action(combo). Every
dispatcher that cannot be rebuilt from a command string stays exactly as
reported, as do mouse binds with no cache entry, since those only act on a
drag.
"""

import importlib.util
import unittest
from pathlib import Path

HINT_SCRIPT = (
    Path(__file__).resolve().parents[2]
    / "Configs/.local/lib/hyde/keybinds/hint-hyprland.py"
)


# Exactly what hyprctl + the cache report for the Application Finder bind
# (SUPER + A -> hyde-shell rofilaunch d).
SUPER_MODMASK = 64
APP_FINDER_COMBO = "SUPER + A"
APP_FINDER_COMMAND = "hyde-shell rofilaunch d"
EXPECTED_DISPATCH = f'hl.dsp.exec_cmd("{APP_FINDER_COMMAND}")'
# What a combo missing from the cache dispatches instead: the action
# hyde/binds.lua recorded for it.
EXPECTED_ACTION = f'hyde.binds.action("{APP_FINDER_COMBO}")'


def load_hint_module():
    spec = importlib.util.spec_from_file_location("hint_hyprland", HINT_SCRIPT)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


hint = load_hint_module()


def make_bind(dispatcher, arg, key="a", modmask=SUPER_MODMASK):
    """Minimal `hyprctl binds -j` entry with no description, so
    expand_meta_data() synthesizes one from dispatcher/arg like the real
    Application Finder bind."""
    return {
        "dispatcher": dispatcher,
        "arg": arg,
        "key": key,
        "keycode": 0,
        "modmask": modmask,
        "submap": "",
        "has_description": False,
    }


def expand(bind, bind_commands=None):
    binds = [bind]
    hint.expand_meta_data(
        binds,
        bind_commands
        if bind_commands is not None
        else {APP_FINDER_COMBO: APP_FINDER_COMMAND},
    )
    return binds[0]


class CacheRecoveryTest(unittest.TestCase):
    def test_application_finder_resolves_for_lua_registry_format(self):
        bind = expand(make_bind("__lua", "107"))
        self.assertEqual(bind["dispatcher"], EXPECTED_DISPATCH)
        self.assertEqual(bind["arg"], "")

    def test_application_finder_resolves_for_dispatcher_constructor_format(self):
        # Hyprland 0.57+ reports the constructor name; the arg is the same
        # opaque handle (an int in the live payload).
        bind = expand(make_bind("HL.Dispatcher(exec_cmd)", 107))
        self.assertEqual(bind["dispatcher"], EXPECTED_DISPATCH)
        self.assertEqual(bind["arg"], "")

    def test_other_lua_dispatchers_are_not_rewritten(self):
        # Same combo, same cache, but these cannot be rebuilt from a command
        # string, so hyprctl's report has to survive untouched.
        for dispatcher, arg in (
            ("HL.Dispatcher(window)", 42),
            ("HL.Dispatcher(workspace)", "3"),
        ):
            with self.subTest(dispatcher=dispatcher):
                bind = expand(make_bind(dispatcher, arg))
                self.assertEqual(bind["dispatcher"], dispatcher)
                self.assertEqual(bind["arg"], arg)

    def test_native_dispatchers_are_not_rewritten(self):
        bind = expand(make_bind("exec", "kitty"))
        self.assertEqual(bind["dispatcher"], "exec")
        self.assertEqual(bind["arg"], "kitty")

    def test_unmapped_combo_falls_back_to_recorded_action(self):
        # Combo absent from the cache: hyde/binds.lua still records the bind's
        # own action per combo, so the hint dispatches that instead.
        for dispatcher in ("__lua", "HL.Dispatcher(exec_cmd)"):
            with self.subTest(dispatcher=dispatcher):
                bind = expand(make_bind(dispatcher, "107", key="q"))
                self.assertEqual(bind["dispatcher"], 'hyde.binds.action("SUPER + Q")')
                self.assertEqual(bind["arg"], "")

    def test_missing_cache_falls_back_to_recorded_action(self):
        for dispatcher in ("__lua", "HL.Dispatcher(exec_cmd)"):
            with self.subTest(dispatcher=dispatcher):
                bind = expand(make_bind(dispatcher, 107), {})
                self.assertEqual(bind["dispatcher"], EXPECTED_ACTION)
                self.assertEqual(bind["arg"], "")

    def test_mouse_bind_with_missing_cache_is_not_rewritten(self):
        # Mouse binds only act on a drag, so there is no action to dispatch;
        # hyprctl's report has to survive untouched.
        for dispatcher in ("__lua", "HL.Dispatcher(exec_cmd)"):
            with self.subTest(dispatcher=dispatcher):
                bind = expand(
                    make_bind(dispatcher, 107, key="mouse:272", modmask=0), {}
                )
                self.assertEqual(bind["dispatcher"], dispatcher)
                self.assertEqual(bind["arg"], 107)


if __name__ == "__main__":
    unittest.main()
