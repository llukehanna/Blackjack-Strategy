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


def print_crash_report(path):
    """Crash logs (.ips) can't be fetched as artifacts from the dev container, so print the
    useful part to the CI log: exception, termination reason and the crashing thread's frames."""
    text = path.read_text(errors="replace")
    print(f"===== CRASH REPORT {path.name} =====")
    try:
        header, body = text.split("\n", 1)
        report = json.loads(body)
        print("exception:", json.dumps(report.get("exception")))
        print("termination:", json.dumps(report.get("termination")))
        asi = report.get("asi")
        if asi:
            print("asi:", json.dumps(asi)[:2000])
        images = report.get("usedImages", [])
        threads = report.get("threads", [])
        crashed = next((t for t in threads if t.get("triggered")), threads[0] if threads else {})
        print("crashed thread:", json.dumps({k: crashed.get(k) for k in ("id", "name", "queue")}))
        print("threads:", json.dumps([{k: t.get(k) for k in ("name", "queue", "triggered")} for t in threads])[:3000])
        for frame in crashed.get("frames", [])[:90]:
            image = images[frame.get("imageIndex", 0)].get("name", "?") if images else "?"
            print(f"  {image}  {frame.get('symbol', '?')}  +{frame.get('symbolLocation', '')}  "
                  f"{frame.get('sourceFile', '')}:{frame.get('sourceLine', '')}")
    except (ValueError, KeyError, IndexError, AttributeError):
        print(text[:6000])
    print("===== END CRASH REPORT =====")


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
                if source.exists() and source.suffix == ".ips":
                    print_crash_report(source)
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
