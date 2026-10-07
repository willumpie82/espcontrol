#!/usr/bin/env bash
# Compile and flash dev.yaml over USB serial, without wiping NVS.
#
# `esphome run`/`esphome upload` over serial always writes the merged
# firmware.factory.bin starting at offset 0x0, which is a single
# contiguous image covering bootloader + partition table + app - this
# also overwrites the NVS partition (0x9000-0x16000) in between, silently
# wiping WiFi credentials (and anything else persisted to flash, e.g.
# switch states) on every single flash. Confirmed on hardware: using
# `esptool write-flash` with the same four files at their real individual
# partition offsets instead - which is the exact command ESPHome's own
# build step prints as a manual fallback - skips over the NVS range
# entirely and preserves everything in it across flashes.
#
# Usage:
#   ./flash_serial.sh              # auto-detect the port
#   ./flash_serial.sh <port>       # use a specific port, e.g. /dev/cu.usbmodem101
set -euo pipefail
cd "$(dirname "$0")"
source .venv/bin/activate

PORT="${1:-}"
if [ -z "$PORT" ]; then
  PORT="$(ls /dev/cu.usbmodem* 2>/dev/null | head -1)"
  if [ -z "$PORT" ]; then
    echo "No /dev/cu.usbmodem* device found - plug in the board or pass a port explicitly." >&2
    exit 1
  fi
fi

esphome compile dev.yaml

BUILD_DIR=".esphome/build/espcontrol-t-display-s3-long/build"
esptool --before default-reset --after hard-reset --baud 460800 --port "$PORT" --chip esp32s3 \
  write-flash -z --flash-mode dio --flash-size 16MB --flash-freq 80m \
  0x0 "$BUILD_DIR/bootloader/bootloader.bin" \
  0x8000 "$BUILD_DIR/partition_table/partition-table.bin" \
  0x16000 "$BUILD_DIR/ota_data_initial.bin" \
  0x20000 "$BUILD_DIR/espcontrol-t-display-s3-long.bin"

echo "Flashed. Watch logs with: esphome logs dev.yaml --device $PORT"
