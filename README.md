# Broadcom Stingray PS225 Lab

Community hardware/software notes for the Broadcom Stingray PS225 SmartNIC / DPU platform.

Repository target:

```text
https://github.com/AudiNV/Broadcom-Stingray-PS225
```

## Current Hardware

- 2x PS225-H16 cards
- 2x PS225-H08 cards
- 1x official Broadcom USB-to-3.5mm TRRS serial console cable
- Broadcom PS225 / BCM5880X documentation archive

## Inventory Summary

| Card | Assembly Number | Model | Revision | Expected Memory | Status |
|---|---|---|---|---:|---|
| Card 01 | BCM958802A8046C | PS225-H16 | Rev 17 | 16GB | Untested |
| Card 02 | BCM958802A8046C | PS225-H16 | Rev 15 | 16GB | Untested |
| Card 03 | BCM958802A8028E | PS225-H08 | Rev E | 8GB ECC estimated | Untested |
| Card 04 | BCM958802A8028C | PS225-H08 | Rev C | 8GB | Untested |

See [`hardware/inventory.md`](hardware/inventory.md) for detailed card-by-card information.

## Key Platform Features

- Broadcom Stingray BCM5880X / BCM58802H SoC
- 8x ARM Cortex-A72 cores at 3.0GHz
- PCIe 3.0 x8 host interface
- Dual 25GbE SFP28 ports
- SR-IOV support
- RoCE v1/v2 support
- TruFlow flow acceleration
- Line-rate crypto engine
- RAID5/6 / erasure acceleration engine
- Onboard eMMC storage
- Onboard SPI flash
- 3.5mm TRRS serial console

## Repo Layout

```text
docs/                  Broadcom and component reference documents
hardware/              Card photos, labels, inventory, cable notes
bootlogs/              Captured serial boot logs
scripts/               Host-side collection scripts
firmware/              Firmware notes and dumps; do not commit proprietary blobs blindly
software/              Driver / userspace notes
reverse-engineering/   Boot, flash, partition, and recovery findings
research/              Analysis notes
```

## Current Focus

1. Preserve hardware identification details.
2. Capture serial boot logs from all cards.
3. Capture host PCIe enumeration.
4. Dump original eMMC/SPI contents from working cards before flashing anything.
5. Compare H08 vs H16 images and NVRAM configuration.

## Caution

Do not flash or overwrite any card until the original boot logs, PCI IDs, eMMC layout, SPI/NVRAM contents, and firmware versions have been captured.
