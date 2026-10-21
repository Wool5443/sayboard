#!/usr/bin/env python3
"""Check the device app, keyboard, and linked dynamic frameworks before signing."""

import plistlib
import struct
import sys
import zipfile


def signature_entitlements(executable, offset, length):
    signature = executable[offset:offset + length]
    magic, size, count = struct.unpack_from(">III", signature)
    assert magic == 0xFADE0CC0 and size <= len(signature), "Invalid signature superblob"
    for index in range(count):
        slot, blob_offset = struct.unpack_from(">II", signature, 12 + index * 8)
        if slot == 5:
            blob_magic, blob_size = struct.unpack_from(">II", signature, blob_offset)
            assert blob_magic == 0xFADE7171 and blob_offset + blob_size <= size, "Invalid entitlement blob"
            return plistlib.loads(signature[blob_offset + 8:blob_offset + blob_size])
    raise AssertionError("Missing App Group entitlements in signature")


def verify(path, sidestore=False):
    with zipfile.ZipFile(path) as ipa:
        app = "Payload/Sayboard.app/"
        keyboard = app + "PlugIns/SayboardKeyboard.appex/"
        names = set(ipa.namelist())
        for root, expected_id in ((app, "app.sayboard"), (keyboard, "app.sayboard.keyboard")):
            info = plistlib.loads(ipa.read(root + "Info.plist"))
            assert info["CFBundleIdentifier"] == expected_id, info["CFBundleIdentifier"]
            assert float(info["MinimumOSVersion"]) >= 17, info["MinimumOSVersion"]
            executable = ipa.read(root + info["CFBundleExecutable"])
            # The build deliberately emits a thin ARM64 Mach-O for physical iPhones.
            magic, cpu, _, _, count, _, _, _ = struct.unpack_from("<8I", executable)
            assert magic == 0xFEEDFACF and cpu == 0x0100000C, "Expected thin ARM64 Mach-O"
            offset = 32
            entitlements = None
            for _ in range(count):
                command, size = struct.unpack_from("<II", executable, offset)
                assert size >= 8 and offset + size <= len(executable), "Invalid load command"
                if command in (0xC, 0x80000018, 0x8000001F):
                    name_offset = struct.unpack_from("<I", executable, offset + 8)[0]
                    library = executable[offset + name_offset:offset + size].split(b"\0", 1)[0].decode()
                    if library.startswith("@rpath/") and ".framework/" in library:
                        relative = library.removeprefix("@rpath/")
                        assert any(prefix + "Frameworks/" + relative in names
                                   for prefix in (root, app)), f"Missing framework: {library}"
                if command == 0x1D:
                    data_offset, data_size = struct.unpack_from("<II", executable, offset + 8)
                    if sidestore:
                        entitlements = signature_entitlements(executable, data_offset, data_size)
                offset += size
            if sidestore:
                assert entitlements == {"com.apple.security.application-groups": ["group.app.sayboard"]}, (
                    f"Incorrect SideStore entitlements in {expected_id}: {entitlements}"
                )
        extension = plistlib.loads(ipa.read(keyboard + "Info.plist"))["NSExtension"]
        assert extension["NSExtensionPointIdentifier"] == "com.apple.keyboard-service"
        assert extension["NSExtensionAttributes"]["RequestsOpenAccess"] is True
    print("IPA verified: ARM64 app, keyboard extension, and linked frameworks present")
    if sidestore:
        print("SideStore metadata verified: both targets declare group.app.sayboard")


if __name__ == "__main__":
    verify(sys.argv[1], sidestore="--sidestore" in sys.argv[2:])
