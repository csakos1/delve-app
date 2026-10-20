#!/usr/bin/env python3
"""One-off, idempotent tweaks to the Android project that `flutter create` made.

- launcher label "Delve"
- INTERNET permission in the main manifest (debug-only by default)
- no cleartext traffic (the server is HTTPS on the tailnet), no cloud backup of
  app data (the device token lives in secure storage)
- checks that the applicationId is hu.csakos.delve
"""
import pathlib
import re
import sys

root = pathlib.Path(__file__).resolve().parent.parent / "android"
manifest = root / "app/src/main/AndroidManifest.xml"
gradle = root / "app/build.gradle.kts"
if not manifest.exists():
    sys.exit(f"missing {manifest}: run flutter create first")

m = manifest.read_text()
orig = m
m = re.sub(r'android:label="[^"]*"', 'android:label="Delve"', m, count=1)
perm = '<uses-permission android:name="android.permission.INTERNET"/>'
if perm not in m:
    m = re.sub(r"(<manifest[^>]*>)", r"\1\n    " + perm, m, count=1)
for attr in ('android:usesCleartextTraffic="false"', 'android:allowBackup="false"'):
    if attr.split("=")[0] not in m:
        m = m.replace("<application", "<application\n        " + attr, 1)
if m != orig:
    manifest.write_text(m)
    print(f"updated {manifest.relative_to(root.parent)}")
else:
    print("manifest already set up")

if gradle.exists():
    g = gradle.read_text()
    found = re.search(r'applicationId\s*=\s*"([^"]+)"', g)
    app_id = found.group(1) if found else None
    if app_id != "hu.csakos.delve":
        sys.exit(f"applicationId is {app_id!r}, expected 'hu.csakos.delve'")
    print("applicationId hu.csakos.delve ok")
else:
    sys.exit(f"missing {gradle}")
