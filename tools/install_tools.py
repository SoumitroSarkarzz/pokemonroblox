#!/usr/bin/env python3
"""Install a pinned official Roblox file validator with TLS and hash checks."""
import hashlib
import io
from pathlib import Path
import platform
import urllib.request
import zipfile

VERSION = '0.9.1'
ARCHIVE_HASH = '7c8a3d6c53f63e629f00373dc4d91513e472a829d9096fec1f6cd0d4f4fefcc5'
BINARY_HASH = '057c4b3e70c928af73646975d1df11579b0a5ccfa72f274af8c6d135fc9f4d34'
DEST = Path('/workspace/pokemon-tools/rbxmk')
if DEST.exists() and hashlib.sha256(DEST.read_bytes()).hexdigest() == BINARY_HASH:
    print('rbxmk 0.9.1 already verified')
else:
    if platform.system() != 'Linux' or platform.machine() != 'x86_64':
        raise SystemExit('This optional validator installer targets Linux x86_64. The Python place builder is portable.')
    url = f'https://github.com/Anaminus/rbxmk/releases/download/v{VERSION}/rbxmk-v{VERSION}-linux-amd64.zip'
    with urllib.request.urlopen(url, timeout=60) as response:
        archive = response.read()
    if hashlib.sha256(archive).hexdigest() != ARCHIVE_HASH:
        raise SystemExit('rbxmk archive checksum mismatch; refusing installation')
    with zipfile.ZipFile(io.BytesIO(archive)) as z:
        binary = z.read('rbxmk')
    if hashlib.sha256(binary).hexdigest() != BINARY_HASH:
        raise SystemExit('rbxmk executable checksum mismatch; refusing installation')
    DEST.parent.mkdir(exist_ok=True)
    DEST.write_bytes(binary)
    DEST.chmod(0o755)
    print(f'Installed and verified {DEST}')
