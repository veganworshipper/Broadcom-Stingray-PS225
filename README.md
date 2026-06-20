# Broadcom Stingray PS225 Lab

Community documentation and bring-up notes for Broadcom Stingray PS225 / BCM5880X SmartNIC / DPU cards.

## Current Hardware Inventory

| Card | Assembly / Identifier | Model | Memory | Revision / Suffix | Build Date | Dev ID | Status |
|---|---|---|---:|---|---|---|---|
| Card 01 | BCM958802A8046C | PS225-H16 | 16 GB DDR4 | Rev 17 | 2020-03-05 | DEV0000 | Untested |
| Card 02 | BCM958802A8046C | PS225-H16 | 16 GB DDR4 | Rev 15 | 2019-12-10 | DEV0000 | Untested |
| Card 03 | BCM958802A8028E | PS225-H08 | 8 GB DDR4 | Rev/Suffix E | Unknown | Unknown | Untested |
| Card 04 | BCM958802A8028C | PS225-H08 | 8 GB DDR4 | Rev/Suffix C | 2021-12-27 | DEV0023 | Untested |

## Accessories

| Item | Identifier | Notes |
|---|---|---|
| Broadcom USB to 3.5 mm TRRS console cable | P/N 12233 / 0530 / 2201 | Official Broadcom console cable for the PS225 UART jack |

## Known PS225 Platform Features

- PCIe 3.0 x8 host interface
- Dual SFP28 network ports, 10GbE / 25GbE capable
- BCM5880X / BCM58802H Stingray SoC
- 8-core ARMv8 Cortex-A72 processor subsystem at 3.0 GHz
- 4 GB, 8 GB, or 16 GB DDR4 variants
- 16 GB onboard eMMC
- 8 MB SPI flash
- SR-IOV support up to 128 VFs
- RoCE v1/v2 support
- TruFlow configurable flow accelerator
- Hardware crypto engine
- RAID 5/6 acceleration
- UART console exposed through the 3.5 mm jack on the bracket

## Repository Layout

```text
hardware/              Card photos, labels, physical notes
bootlogs/              UART boot captures per card
firmware/              User-created firmware/image notes and hashes
software/              Host drivers, commands, tool notes
reverse-engineering/   eMMC layouts, SPI dumps, boot process notes
scripts/               Helper scripts
docs/                  Datasheets, user guides, app notes, whitepapers
```

## Bring-up Plan

1. Photograph and catalog all cards.
2. Install one known H16 card in a Linux host.
3. Connect the official USB-to-TRRS console cable.
4. Capture full UART boot log.
5. Capture host-side PCI information with `lspci -nn` and `lspci -vv`.
6. If Linux boots on the ARM side, dump eMMC partition layout and NVRAM information before changing anything.
7. Repeat for all four cards.
8. Compare H08 vs H16 firmware, eMMC layout, NVRAM config, and boot logs.

## Safe First Commands

```bash
lspci -nn | grep -i broadcom
lspci -nn | grep 14e4
lspci -vv -s <pci-device>
```

Serial console starting point:

```bash
screen /dev/ttyUSB0 115200
# or
picocom -b 115200 /dev/ttyUSB0
```

Do not flash firmware until the original state of each card has been captured.
