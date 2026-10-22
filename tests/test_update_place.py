"""Protect Studio-imported assets while updating embedded source."""
from pathlib import Path
import importlib.util
import tempfile
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('update_place', ROOT / 'tools/update_place.py')
updater = importlib.util.module_from_spec(spec)
spec.loader.exec_module(updater)

class PreserveStudioWork(unittest.TestCase):
    def test_imported_model_and_metadata_survive(self):
        with tempfile.TemporaryDirectory() as directory:
            tree = ET.parse(ROOT / 'build/KantoArena.rbxlx')
            root = tree.getroot()
            pokemon = updater.child(updater.child(root, 'ReplicatedStorage'), 'Pokemon')
            model = updater.child(updater.child(updater.child(pokemon, 'Models'), '025_Pikachu'), 'ModelSlot')
            imported = ET.SubElement(model, 'Item', {'class': 'Model', 'referent': 'RBXImportedByDeveloper'})
            properties = ET.SubElement(imported, 'Properties')
            ET.SubElement(properties, 'string', name='Name').text = 'DeveloperCustomPikachu'
            ET.SubElement(properties, 'string', name='DeveloperNote').text = 'Preserve this object exactly'
            before = ET.tostring(imported)
            input_path = Path(directory) / 'Working.rbxlx'
            output = Path(directory) / 'Updated.rbxlx'
            tree.write(input_path)
            original_input = input_path.read_bytes()
            updater.merge(input_path, output)
            self.assertEqual(input_path.read_bytes(), original_input)
            new_root = ET.parse(output).getroot()
            saved = next(n for n in new_root.iter('Item') if n.attrib['referent'] == 'RBXImportedByDeveloper')
            self.assertEqual(ET.tostring(saved), before)
            with self.assertRaises(ValueError):
                updater.merge(input_path, output)

    def test_additive_upgrade_creates_new_modules(self):
        with tempfile.TemporaryDirectory() as directory:
            tree = ET.parse(ROOT / 'build/KantoArena.rbxlx')
            shared = updater.child(updater.child(tree.getroot(), 'ReplicatedStorage'), 'Shared')
            shared.remove(updater.child(shared, 'UITheme'))
            working = Path(directory) / 'Old.rbxlx'
            output = Path(directory) / 'Upgrade.rbxlx'
            tree.write(working)
            updater.merge(working, output)
            updated_shared = updater.child(updater.child(ET.parse(output).getroot(), 'ReplicatedStorage'), 'Shared')
            module = updater.child(updated_shared, 'UITheme')
            self.assertEqual(module.attrib['class'], 'ModuleScript')
            self.assertEqual(module.findtext("Properties/ProtectedString[@name='Source']"), (ROOT / 'src/shared/UITheme.luau').read_text())

    def test_refuses_non_script_name_collision(self):
        with tempfile.TemporaryDirectory() as directory:
            tree = ET.parse(ROOT / 'build/KantoArena.rbxlx')
            shared = updater.child(updater.child(tree.getroot(), 'ReplicatedStorage'), 'Shared')
            node = updater.child(shared, 'UITheme')
            node.attrib['class'] = 'Folder'
            props = node.find('Properties')
            props.remove(node.find("Properties/ProtectedString[@name='Source']"))
            working = Path(directory) / 'Collision.rbxlx'
            output = Path(directory) / 'Upgrade.rbxlx'
            tree.write(working)
            original = working.read_bytes()
            with self.assertRaises(ValueError):
                updater.merge(working, output)
            self.assertFalse(output.exists())
            self.assertEqual(working.read_bytes(), original)

if __name__ == '__main__':
    unittest.main()
