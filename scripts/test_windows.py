import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('diff', Path(__file__).with_name('run-windows.py'))
diff = importlib.util.module_from_spec(spec)
spec.loader.exec_module(diff)


class DiffTests(unittest.TestCase):
    def test_parent_folder_discovers_only_changed_repositories(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in ('changed repo', 'clean', 'node_modules/ignored'):
                repo = root / name
                repo.mkdir(parents=True)
                subprocess.run(['git', 'init', '-q', str(repo)], check=True)
                if name != 'clean':
                    (repo/'file.txt').write_text('changed')
            self.assertEqual(diff.repositories(root), [str(root/'changed repo')])
            self.assertEqual(Path(diff.repositories(root/'clean')[0]), root/'clean')

    def test_windows_safe_state_and_diff_tab_toggle(self):
        with tempfile.TemporaryDirectory() as directory, patch.dict(os.environ, {'HERDR_PLUGIN_STATE_DIR': directory, 'HERDR_PANE_ID': 'w1:p1', 'HERDR_TAB_ID': 'w1:t1', 'HERDR_WORKSPACE_ID': 'w1'}):
            calls = []
            def rpc(*args):
                calls.append(args)
                if args[:2] == ('pane', 'get'):
                    return {'pane': {'cwd': directory}}
                if args[:3] == ('plugin', 'pane', 'open'):
                    return {'plugin_pane': {'pane': {'pane_id': 'w1:p2', 'tab_id': 'w1:t2'}}}
                return {}
            with patch.object(diff, 'rpc', side_effect=rpc), patch.object(diff, 'repositories', return_value=[directory]):
                diff.toggle()
                state = next(Path(directory).glob('pane-*.json'))
                self.assertNotIn(':', state.name)
                self.assertEqual(json.loads(state.read_text())['origin'], 'w1:t1')
                self.assertTrue(any('diff-windows' in call for call in calls))
                calls.clear()
                diff.toggle()
                self.assertIn(('tab', 'close', 'w1:t2'), calls)
                self.assertIn(('tab', 'focus', 'w1:t1'), calls)
                self.assertFalse(state.exists())


if __name__ == '__main__':
    unittest.main()
