#!/usr/bin/env python3
"""Merge code into a Studio-saved XML place without replacing imported assets.

Usage: python3 tools/update_place.py studio/Working.rbxlx build/Updated.rbxlx
Always writes a separate file and refuses to overwrite an existing output.
"""
from pathlib import Path
import sys
import hashlib
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]

def child(parent, name):
    for node in parent.findall('Item'):
        if node.findtext("Properties/string[@name='Name']") == name:
            return node
    raise ValueError(f'Missing project node: {name}')


def merge(input_path, output_path):
    if output_path.exists():
        raise ValueError('Output exists. Choose a new file to preserve your work.')
    tree = ET.parse(input_path)
    root = tree.getroot()
    groups = [
        (ROOT / 'src/shared', ['ReplicatedStorage', 'Shared']),
        (ROOT / 'src/server', ['ServerScriptService', 'Services']),
        (ROOT / 'src/client', ['StarterPlayer', 'StarterPlayerScripts', 'Controllers']),
        (ROOT / 'src/studio', ['ServerStorage']),
    ]
    count = 0
    for directory, components in groups:
        group = root
        for name in components:
            group = child(group, name)
        for file in sorted(directory.glob('*.luau')):
            name = file.name.removesuffix('.server.luau').removesuffix('.client.luau').removesuffix('.luau')
            try:
                node = child(group, name)
            except ValueError:
                reference = 'RBXUpgrade' + hashlib.sha256(str(file.relative_to(ROOT)).encode()).hexdigest()[:20]
                if any(item.attrib.get('referent') == reference for item in root.iter('Item')):
                    raise ValueError(f'Conflicting generated reference for {name}')
                cls = 'Script' if file.name.endswith('.server.luau') else 'LocalScript' if file.name.endswith('.client.luau') else 'ModuleScript'
                node = ET.SubElement(group, 'Item', {'class': cls, 'referent': reference})
                props = ET.SubElement(node, 'Properties')
                ET.SubElement(props, 'string', name='Name').text = name
                ET.SubElement(props, 'ProtectedString', name='Source')
            source = node.find("Properties/ProtectedString[@name='Source']")
            if source is None:
                raise ValueError(f'No Source property on {name}')
            source.text = file.read_text()
            count += 1
    output_path.parent.mkdir(parents=True, exist_ok=True)
    tree.write(output_path, encoding='utf-8', xml_declaration=False)
    print(f'Updated {count} sources; preserved all other place objects: {output_path}')

if __name__ == '__main__':
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    merge(Path(sys.argv[1]), Path(sys.argv[2]))
