#!/usr/bin/env python3
"""Deterministic, dependency-free Roblox XML place/asset builder.

Rebuilds generated output only; never serializes over an edited Studio place.
"""
from pathlib import Path
import base64
import hashlib
import json
import re
import struct
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / 'build'
ANIMATIONS = 'Idle Walk Run Jump Fall Land Dash M1_1 M1_2 M1_3 M1_4 Ability1 Ability2 Ability3 Ability4 Hit Knockback Defeat Spawn SwitchIn SwitchOut Victory'.split()
SOUNDS = 'Spawn Attack Ability1 Ability2 Ability3 Ability4 Hit Defeat'.split()
rows = re.findall(r'\{(\d+), "(\w+)", "(\w+)"(?:, "(\w+)")?\}', (ROOT / 'src/shared/Kanto.luau').read_text())
assert len(rows) == 151
serial = 0


def prop(item, kind, name, value):
    node = ET.SubElement(item.find('Properties'), kind, name=name)
    if isinstance(value, dict):
        for k, v in value.items():
            ET.SubElement(node, k).text = str(v)
    else:
        node.text = str(value)
    return node


def item(parent, cls, name):
    global serial
    serial += 1
    node = ET.SubElement(parent, 'Item', {'class': cls, 'referent': f'RBX{serial}'})
    ET.SubElement(node, 'Properties')
    prop(node, 'string', 'Name', name)
    return node


def folder(parent, name):
    return item(parent, 'Folder', name)


def attributes(node, values):
    data = struct.pack('<I', len(values))
    for name, value in values.items():
        encoded = name.encode()
        data += struct.pack('<I', len(encoded)) + encoded
        if isinstance(value, bool):
            data += b'\x03' + bytes([int(value)])
        elif isinstance(value, (int, float)):
            data += b'\x06' + struct.pack('<d', value)
        else:
            encoded = value.encode()
            data += b'\x02' + struct.pack('<I', len(encoded)) + encoded
    prop(node, 'BinaryString', 'AttributesSerialize', base64.b64encode(data).decode())


def vector(node, name, x, y, z):
    prop(node, 'Vector3', name, {'X': x, 'Y': y, 'Z': z})


def source(parent, name, code, cls='ModuleScript'):
    node = item(parent, cls, name)
    prop(node, 'ProtectedString', 'Source', code)
    return node


def assets(parent):
    pokemon = folder(parent, 'Pokemon')
    groups = {name: folder(pokemon, name) for name in ('Models', 'Icons', 'Data', 'Animations', 'VFX', 'Sounds')}
    for number, name, typ, typ2 in rows:
        number = int(number)
        full = f'{number:03d}_{name}'
        slot = folder(groups['Models'], full)
        attributes(slot, {'PokemonID': number, 'PokemonName': name, 'Region': 'Kanto', 'Generation': 1,
                          'ModelInstalled': False, 'IconInstalled': False, 'AnimationsInstalled': False, 'ReadyForBattle': True})
        prop(slot, 'BinaryString', 'Tags', base64.b64encode(b'PokemonAssetSlot').decode())
        container = folder(slot, 'ModelSlot')
        model = item(container, 'Model', 'PlaceholderModel')
        body = item(model, 'Part', 'Body')
        vector(body, 'size', 3, 4, 3)
        prop(body, 'bool', 'Anchored', 'true')
        prop(body, 'bool', 'CanCollide', 'false')
        prop(body, 'token', 'shape', 0)
        import colorsys
        r, g, b = colorsys.hsv_to_rgb(number/151, .65, .95)
        prop(body, 'Color3uint8', 'Color3uint8', (round(r*255)<<16)+(round(g*255)<<8)+round(b*255))
        prop(model, 'Ref', 'PrimaryPart', body.attrib['referent'])
        gui = item(body, 'BillboardGui', 'Identity')
        prop(gui, 'UDim2', 'Size', {'XS': 0, 'XO': 180, 'YS': 0, 'YO': 75})
        vector(gui, 'StudsOffset', 0, 3, 0)
        label = item(gui, 'TextLabel', 'Label')
        prop(label, 'UDim2', 'Size', {'XS': 1, 'XO': 0, 'YS': 1, 'YO': 0})
        prop(label, 'float', 'BackgroundTransparency', 1)
        prop(label, 'float', 'TextSize', 14)
        prop(label, 'Color3', 'TextColor3', {'R': 1, 'G': 1, 'B': 1})
        prop(label, 'string', 'Text', f'[{number:03d}] {name.upper()}\n{typ.upper()} • PLACEHOLDER')
        anims = folder(slot, 'Animations')
        for animation in ANIMATIONS:
            item(anims, 'Animation', animation)
        vfx = folder(slot, 'VFX')
        for index in range(1, 5):
            folder(vfx, f'Ability{index}')
        sounds = folder(slot, 'Sounds')
        for sound in SOUNDS:
            item(sounds, 'Sound', sound)
        for group in (folder(slot, 'UI'), folder(groups['Icons'], full)):
            for name in ('Icon', 'Portrait'):
                item(group, 'StringValue', name)
    for module in ('PokemonDatabase', 'PokemonModelSettings'):
        source(groups['Data'], module, f'return require(game.ReplicatedStorage.Shared.{module})\n')
    return pokemon


def root():
    return ET.Element('roblox', {'version': '4'})


def write(tree, path):
    ET.ElementTree(tree).write(path, encoding='utf-8', xml_declaration=False)


def build():
    BUILD.mkdir(exist_ok=True)
    place = root()
    workspace = item(place, 'Workspace', 'Workspace')
    prop(workspace, 'bool', 'StreamingEnabled', 'true')
    # Explicitly Studio-only: DataService ignores this flag in published servers.
    attributes(workspace, {'UseMockData': True})
    replicated = item(place, 'ReplicatedStorage', 'ReplicatedStorage')
    shared = folder(replicated, 'Shared')
    for file in sorted((ROOT / 'src/shared').glob('*.luau')):
        source(shared, file.stem, file.read_text())
    assets(replicated)
    server = item(place, 'ServerScriptService', 'ServerScriptService')
    services = folder(server, 'Services')
    for file in sorted((ROOT / 'src/server').glob('*.luau')):
        is_script = file.name.endswith('.server.luau')
        source(services, file.name.removesuffix('.server.luau') if is_script else file.stem, file.read_text(), 'Script' if is_script else 'ModuleScript')
    starter = item(place, 'StarterPlayer', 'StarterPlayer')
    scripts = item(starter, 'StarterPlayerScripts', 'StarterPlayerScripts')
    controllers = folder(scripts, 'Controllers')
    for file in sorted((ROOT / 'src/client').glob('*.luau')):
        is_script = file.name.endswith('.client.luau')
        source(controllers, file.name.removesuffix('.client.luau') if is_script else file.stem, file.read_text(), 'LocalScript' if is_script else 'ModuleScript')
    storage = item(place, 'ServerStorage', 'ServerStorage')
    for file in sorted((ROOT / 'src/studio').glob('*.luau')):
        source(storage, file.stem, file.read_text())
    for name in ('Maps', 'ServerCreatureModels', 'BotTemplates'):
        folder(storage, name)
    item(place, 'StarterGui', 'StarterGui')
    write(place, BUILD / 'KantoArena.rbxlx')
    asset = root()
    assets(asset)
    write(asset, BUILD / 'Pokemon.rbxmx')
    report = {str(f.relative_to(ROOT)): hashlib.sha256(f.read_bytes()).hexdigest() for f in sorted((ROOT / 'src').rglob('*.luau'))}
    (BUILD / 'manifest.json').write_text(json.dumps({'sources': report, 'pokemon': len(rows)}, indent=2)+'\n')
    print(f'Built {BUILD / "KantoArena.rbxlx"} ({len(report)} Luau sources, {len(rows)} asset slots)')


if __name__ == '__main__':
    build()
