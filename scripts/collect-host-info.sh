#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-ps225-host-capture-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$OUT"
lspci -nn > "$OUT/lspci-nn.txt"
lspci -vv > "$OUT/lspci-vv.txt" || true
dmesg > "$OUT/dmesg.txt" || true
ip addr > "$OUT/ip-addr.txt" || true
ethtool -i $(ls /sys/class/net | grep -v lo | head -n1) > "$OUT/ethtool-example.txt" 2>/dev/null || true
echo "Captured host information in $OUT"
