#!/usr/bin/env bash
# Print the newest available iPhone simulator, so builds don't depend on a
# hardcoded device name that may not exist on a given Xcode install or CI runner.
set -euo pipefail

xcrun simctl list devices available -j | python3 -c '
import json, sys

runtimes = json.load(sys.stdin)["devices"]
best_key, best_name = None, None
for runtime, devices in runtimes.items():
    if "iOS" not in runtime:
        continue
    try:
        key = tuple(int(p) for p in runtime.split("iOS-")[-1].split("-"))
    except ValueError:
        continue
    for dev in devices:
        if dev["name"].startswith("iPhone"):
            if best_key is None or key > best_key:
                best_key, best_name = key, dev["name"]
            break

if not best_name:
    sys.exit("pick-simulator: no available iPhone simulator found")
print(best_name)
'
