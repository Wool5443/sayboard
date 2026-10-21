import importlib.util
import plistlib
import struct
import tempfile
import unittest
import zipfile
from pathlib import Path

SPEC = importlib.util.spec_from_file_location(
    "verify_ipa", Path(__file__).resolve().parents[1] / "verify-sideload-ipa.py"
)
VERIFY = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VERIFY)
GROUP = {"com.apple.security.application-groups": ["group.app.sayboard"]}


def executable(entitlements):
    if entitlements is None:
        return struct.pack("<8I", 0xFEEDFACF, 0x0100000C, 0, 2, 0, 0, 0, 0)
    xml = plistlib.dumps(entitlements)
    blob = struct.pack(">II", 0xFADE7171, 8 + len(xml)) + xml
    signature = struct.pack(">5I", 0xFADE0CC0, 20 + len(blob), 1, 5, 20) + blob
    header = struct.pack("<8I", 0xFEEDFACF, 0x0100000C, 0, 2, 1, 16, 0, 0)
    return header + struct.pack("<4I", 0x1D, 16, 48, len(signature)) + signature


class SideStoreIPATests(unittest.TestCase):
    def check(self, app_entitlements, keyboard_entitlements, sidestore=True):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "fixture.ipa"
            app = "Payload/Sayboard.app/"
            with zipfile.ZipFile(path, "w") as archive:
                for root, identifier, binary_name, entitlements in (
                    (app, "app.sayboard", "Sayboard", app_entitlements),
                    (app + "PlugIns/SayboardKeyboard.appex/", "app.sayboard.keyboard",
                     "SayboardKeyboard", keyboard_entitlements),
                ):
                    info = {"CFBundleIdentifier": identifier, "MinimumOSVersion": "17.0",
                            "CFBundleExecutable": binary_name}
                    if identifier.endswith(".keyboard"):
                        info["NSExtension"] = {
                            "NSExtensionPointIdentifier": "com.apple.keyboard-service",
                            "NSExtensionAttributes": {"RequestsOpenAccess": True},
                        }
                    archive.writestr(root + "Info.plist", plistlib.dumps(info))
                    archive.writestr(root + binary_name, executable(entitlements))
            VERIFY.verify(path, sidestore=sidestore)

    def test_both_targets_declare_the_preserved_group(self):
        self.check(GROUP, GROUP)

    def test_missing_group_in_either_target_is_rejected(self):
        for app, keyboard in ((None, GROUP), (GROUP, None), ({}, GROUP), (GROUP, {})):
            with self.subTest(app=app, keyboard=keyboard), self.assertRaises(AssertionError):
                self.check(app, keyboard)

    def test_wrong_group_and_extra_entitlements_are_rejected(self):
        for invalid in (
            {"com.apple.security.application-groups": ["group.app.sayboard.shared"]},
            {**GROUP, "get-task-allow": True},
        ):
            with self.subTest(invalid=invalid), self.assertRaises(AssertionError):
                self.check(invalid, GROUP)

    def test_original_unsigned_iloader_format_remains_supported(self):
        self.check(None, None, sidestore=False)

    def test_truncated_signature_is_rejected(self):
        with self.assertRaises((AssertionError, struct.error)):
            VERIFY.signature_entitlements(b"short", 0, 5)


if __name__ == "__main__":
    unittest.main()
