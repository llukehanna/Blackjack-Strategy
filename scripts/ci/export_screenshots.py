#!/usr/bin/env python3
"""Copy the screenshot attachments out of an .xcresult bundle.

Usage: export_screenshots.py <bundle.xcresult> <output-dir>

Uses `xcrun xcresulttool export attachments` (Xcode 16+), then names each PNG after
the attachment name set in DesignScreenshotTests (e.g. 01-hub.png).
"""
import json
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile


def attachments(node):
    """Yield every dict that describes one exported attachment, wherever it sits in the manifest."""
    if isinstance(node, dict):
        if "exportedFileName" in node:
            yield node
        for value in node.values():
            yield from attachments(value)
    elif isinstance(node, list):
        for value in node:
            yield from attachments(value)


def clean_name(attachment):
    raw = attachment.get("suggestedHumanReadableName") or attachment["exportedFileName"]
    stem = pathlib.Path(raw).stem
    # Xcode appends "_<index>_<UUID>" to the attachment name; drop it.
    stem = re.sub(r"_\d+_[0-9A-Fa-f-]{36}$", "", stem)
    return re.sub(r"[^A-Za-z0-9._-]", "_", stem) + pathlib.Path(attachment["exportedFileName"]).suffix


def main():
    bundle, output = sys.argv[1], pathlib.Path(sys.argv[2])
    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run(["xcrun", "xcresulttool", "export", "attachments",
                        "--path", bundle, "--output-path", tmp], check=True)
        manifest_path = pathlib.Path(tmp) / "manifest.json"
        count = 0
        if manifest_path.exists():
            for attachment in attachments(json.loads(manifest_path.read_text())):
                source = pathlib.Path(tmp) / attachment["exportedFileName"]
                if source.exists():
                    shutil.copy(source, output / clean_name(attachment))
                    count += 1
        else:
            for source in pathlib.Path(tmp).glob("*.png"):
                shutil.copy(source, output / source.name)
                count += 1
    print(f"Exported {count} screenshots to {output}")


if __name__ == "__main__":
    main()
