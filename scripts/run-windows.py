"""Native Windows diff tab actions and isolated Neovim launcher."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
from urllib.parse import quote


def call(args, check=True):
    return subprocess.run(args, capture_output=True, text=True, encoding='utf-8', errors='replace', check=check, creationflags=subprocess.CREATE_NO_WINDOW)


def rpc(*args):
    return json.loads(call([os.environ.get('HERDR_BIN_PATH', 'herdr'), *args]).stdout)['result']


def repositories(cwd):
    result = call(['git', '-C', str(cwd), 'rev-parse', '--show-toplevel'], check=False)
    if result.returncode == 0:
        return [result.stdout.strip()]
    repos = []
    for root, dirs, files in os.walk(cwd):
        relative = Path(root).relative_to(cwd)
        if '.git' in dirs or '.git' in files:
            changed = call(['git', '-C', root, 'status', '--porcelain'], check=False)
            if changed.returncode == 0 and changed.stdout.strip():
                repos.append(str(Path(root)))
            dirs[:] = []
        else:
            dirs[:] = [d for d in dirs if d != 'node_modules'] if len(relative.parts) < 2 else []
    return sorted(repos)


def state_dir():
    return Path(os.environ.get('HERDR_PLUGIN_STATE_DIR') or Path(os.environ['LOCALAPPDATA']) / 'herdr/plugins/git-diff')


def nvim_environment():
    state = state_dir() / 'nvim'
    env = os.environ.copy()
    root = Path(__file__).resolve().parent.parent
    env.update(XDG_CONFIG_HOME=str(root), XDG_DATA_HOME=str(state/'data'), XDG_STATE_HOME=str(state/'state'), XDG_CACHE_HOME=str(state/'cache'))
    tools = Path(os.environ['LOCALAPPDATA']) / 'herdr/tools'
    extra = [tools/'nvim-win64/bin', tools, Path('C:/QMK_MSYS/ucrt64/bin')]
    env['PATH'] = os.pathsep.join(str(p) for p in extra if p.is_dir()) + os.pathsep + env.get('PATH', '')
    for key in ('XDG_DATA_HOME', 'XDG_STATE_HOME', 'XDG_CACHE_HOME'):
        Path(env[key]).mkdir(parents=True, exist_ok=True)
    nvim = os.environ.get('HERDR_NVIM') or shutil.which('nvim', path=env['PATH'])
    if not nvim:
        raise RuntimeError('Neovim 0.11.2+ is required; install Neovim or set HERDR_NVIM')
    return nvim, env


def toggle():
    state = state_dir()
    state.mkdir(parents=True, exist_ok=True)
    pane, origin = os.environ['HERDR_PANE_ID'], os.environ['HERDR_TAB_ID']
    filename = state / ('pane-' + quote(origin, safe='') + '.json')
    for path in state.glob('pane-*.json'):
        try:
            saved = json.loads(path.read_text(encoding='utf-8'))
        except (OSError, ValueError):
            continue
        exists = True
        try:
            rpc('pane', 'get', saved['pane'])
        except subprocess.SubprocessError:
            exists = False
        if pane == saved['pane'] or origin == saved['tab'] or (origin == saved['origin'] and exists):
            rpc('tab', 'close', saved['tab'])
            path.unlink(missing_ok=True)
            rpc('tab', 'focus', saved['origin'])
            return
        if origin == saved['origin'] and not exists:
            path.unlink(missing_ok=True)
    current = rpc('pane', 'get', pane)['pane']
    cwd = Path(current.get('foreground_cwd') or current['cwd'])
    repos = repositories(cwd)
    if not repos:
        rpc('notification', 'show', 'Git Diff', '--body', 'No changed repositories: ' + str(cwd))
        return
    repo_file = state / ('repos-' + quote(origin, safe='') + '.txt')
    repo_file.write_text('\n'.join(repos) + '\n', encoding='utf-8')
    created = rpc('plugin', 'pane', 'open', '--plugin', os.environ.get('HERDR_PLUGIN_ID', 'git-diff'), '--entrypoint', 'diff-windows', '--placement', 'tab', '--workspace', os.environ['HERDR_WORKSPACE_ID'], '--env', 'GIT_DIFF_REPOS=' + str(repo_file), '--focus')['plugin_pane']['pane']
    filename.write_text(json.dumps({'pane': created['pane_id'], 'tab': created['tab_id'], 'origin': origin}), encoding='utf-8')
    label = 'diff: ' + (Path(repos[0]).name if len(repos) == 1 else str(len(repos)) + ' repos')
    rpc('tab', 'rename', created['tab_id'], label)
    rpc('tab', 'focus', created['tab_id'])


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else 'toggle'
    if action == 'toggle':
        toggle()
        return 0
    nvim, env = nvim_environment()
    if action == 'environment':
        print(json.dumps({'nvim': nvim, 'env': env}))
        return 0
    if action != 'diff':
        raise ValueError('Unknown action: ' + action)
    return subprocess.call([nvim], env=env)


if __name__ == '__main__':
    raise SystemExit(main())
