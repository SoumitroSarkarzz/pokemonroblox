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

if __name__ == '__main__':
    unittest.main()
