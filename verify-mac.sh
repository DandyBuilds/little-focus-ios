#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
command -v xcodebuild >/dev/null || { echo "Xcode is required. Select it with xcode-select."; exit 1; }
DEVICE_ID=$(xcrun simctl list devices available -j | python3 -c 'import json,sys; d=json.load(sys.stdin); ids=[x["udid"] for runtime,devices in d["devices"].items() if "iOS" in runtime for x in devices if "iPhone" in x["name"] and x.get("isAvailable")]; print(ids[0] if ids else "")')
if [ -z "$DEVICE_ID" ]; then echo "Install an iOS simulator runtime in Xcode Settings > Components."; exit 1; fi
xcodebuild -project LittleFocus.xcodeproj -scheme LittleFocus -destination "platform=iOS Simulator,id=$DEVICE_ID" -derivedDataPath .build test CODE_SIGNING_ALLOWED=NO
