#!/usr/bin/env bash
# Compile and upload dev.yaml over the network (ESPHome native OTA) instead
# of serial. No USB port contention, and OTA never touches the NVS
# partition at all, so WiFi credentials and other persisted state are
# always preserved - unlike a raw serial write-flash of the merged
# firmware.factory.bin (see flash_serial.sh's comment for that story).
#
# Usage:
#   ./flash_ota.sh            # resolve the device via mDNS
#   ./flash_ota.sh <host>     # use a specific IP or hostname instead
set -euo pipefail
cd "$(dirname "$0")"
source .venv/bin/activate

TARGET="${1:-OTA}"
esphome compile dev.yaml
esphome upload dev.yaml --device "$TARGET"
