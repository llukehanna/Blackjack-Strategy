#!/usr/bin/env python3
"""Find or create an iPhone simulator for the design check and publish its UDID.

Usage:
  ensure_simulator.py --key iphone16 --name "iPhone 16" [--fallback "iPhone 16e" ...]

Tries --name first, then each --fallback, on the newest available iOS runtime that
supports the device type. Reuses an existing simulator of that type and runtime, or
creates one with `xcrun simctl create`. Writes `<key>=<udid>` and `<key>_name=<name>`
to $GITHUB_OUTPUT. If no candidate works it writes an empty UDID, prints a GitHub
warning and exits 0, so the workflow can skip that device and still upload the rest.
"""
import argparse
import json
import os
import subprocess
import sys


def simctl_list(*args):
    out = subprocess.run(["xcrun", "simctl", "list", *args, "-j"],
                         check=True, capture_output=True, text=True).stdout
    return json.loads(out)


def version_key(runtime):
    return tuple(int(part) for part in runtime.get("version", "0").split(".") if part.isdigit())


def write_output(key, udid, name):
    path = os.environ.get("GITHUB_OUTPUT")
    lines = f"{key}={udid}\n{key}_name={name}\n"
    if path:
        with open(path, "a") as handle:
            handle.write(lines)
    print(lines, end="")


def find_or_create(name, device_types, runtimes, devices):
    type_id = device_types.get(name)
    if type_id is None:
        print(f"Device type '{name}' is not installed.", file=sys.stderr)
        return None
    for runtime in runtimes:
        supported = {d.get("identifier") for d in runtime.get("supportedDeviceTypes", [])}
        if supported and type_id not in supported:
            continue
        for device in devices.get(runtime["identifier"], []):
            if device.get("deviceTypeIdentifier") == type_id or device.get("name") == name:
                print(f"Reusing {device['name']} ({runtime['name']}): {device['udid']}", file=sys.stderr)
                return device["udid"]
        created = subprocess.run(
            ["xcrun", "simctl", "create", f"BJS {name}", type_id, runtime["identifier"]],
            capture_output=True, text=True)
        if created.returncode == 0:
            udid = created.stdout.strip()
            print(f"Created BJS {name} ({runtime['name']}): {udid}", file=sys.stderr)
            return udid
        print(f"Could not create {name} on {runtime['name']}: {created.stderr.strip()}", file=sys.stderr)
    return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--key", required=True)
    parser.add_argument("--name", required=True)
    parser.add_argument("--fallback", action="append", default=[])
    args = parser.parse_args()

    device_types = {d["name"]: d["identifier"] for d in simctl_list("devicetypes")["devicetypes"]}
    runtimes = [r for r in simctl_list("runtimes")["runtimes"]
                if r.get("isAvailable") and r.get("name", "").startswith("iOS")]
    runtimes.sort(key=version_key, reverse=True)
    devices = simctl_list("devices", "available")["devices"]

    for candidate in [args.name, *args.fallback]:
        udid = find_or_create(candidate, device_types, runtimes, devices)
        if udid:
            if candidate != args.name:
                print(f"::warning::{args.name} unavailable; design screenshots use {candidate} instead.")
            write_output(args.key, udid, candidate)
            return
    print(f"::warning::No simulator for {args.name} or its fallbacks; skipping its design screenshots.")
    write_output(args.key, "", "")


if __name__ == "__main__":
    main()
