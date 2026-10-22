#!/usr/bin/env python3
"""Check packaging with an actual Roblox decoder; preserve failure status."""
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
tool = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('/workspace/pokemon-tools/rbxmk')
binary = root / 'build/KantoArena.rbxl'
binary.unlink(missing_ok=True)
result = subprocess.run([str(tool), 'run', '--include-root', str(root), 'tests/inspect-place.lua'], cwd=root, capture_output=True, text=True)
print(result.stdout, end='')
print(result.stderr, end='', file=sys.stderr)
# rbxmk 0.9.1 can report script errors with status 0; also require this run's sentinel and artifact.
if result.returncode or 'PASS: Roblox XML decoded;' not in result.stdout or not binary.is_file():
    raise SystemExit(result.returncode or 1)
