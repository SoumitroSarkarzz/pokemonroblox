#!/usr/bin/env python3
"""Package built game and source as GitHub-downloadable release files."""
from pathlib import Path
import shutil
import zipfile

root = Path(__file__).resolve().parents[1]
out = root / 'releases'
out.mkdir(exist_ok=True)
shutil.copy2(root / 'build/KantoArena.rbxl', out / 'KantoArena.rbxl')
with zipfile.ZipFile(out / 'KantoArena.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
    for name in ('README.md', 'package.json', 'package-lock.json', '.gitignore'):
        archive.write(root / name, 'KantoArena/' + name)
    for directory in ('src', 'docs', 'tools', 'tests', 'build'):
        for file in sorted((root / directory).rglob('*')):
            if file.is_file() and '__pycache__' not in file.parts and file.suffix != '.pyc':
                archive.write(file, 'KantoArena/' + str(file.relative_to(root)))
with zipfile.ZipFile(out / 'KantoArena.zip') as archive:
    assert archive.testzip() is None, 'Corrupt ZIP'
shutil.copy2(out / 'KantoArena.rbxl', out / 'KantoArena-Polish.rbxl')
shutil.copy2(out / 'KantoArena.zip', out / 'KantoArena-Polish.zip')
print('Packaged releases/KantoArena.rbxl and releases/KantoArena.zip')
