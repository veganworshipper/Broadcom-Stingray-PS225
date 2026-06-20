# Broadcom Stingray PS225 Hardware Inventory

This repository currently documents four Broadcom Stingray PS225 SmartNIC/DPU cards and one official Broadcom USB-to-TRRS console cable.

## Card Inventory

| Card | Assembly Number | Model | Revision | Expected Memory | Memory Evidence | Status |
|---|---|---|---|---:|---|---|
| Card 01 | BCM958802A8046C | PS225-H16 | Rev 17 | 16GB | Broadcom assembly mapping, rear label | Untested |
| Card 02 | BCM958802A8046C | PS225-H16 | Rev 15 | 16GB | Broadcom assembly mapping, rear label | Untested |
| Card 03 | BCM958802A8028E | PS225-H08 | Rev E | 8GB | Micron D9TBK DRAM analysis, assembly ID | Untested |
| Card 04 | BCM958802A8028C | PS225-H08 | Rev C | 8GB | Broadcom assembly mapping, rear label | Untested |

## Card 01

| Field | Value |
|---|---|
| Assembly | BCM958802A8046C |
| Model | PS225-H16 |
| Revision | Rev 17 |
| Build Date | 2020-03-05 |
| Dev ID | DEV0000 |
| Expected DDR4 | 16GB |
| Status | Untested |

## Card 02

| Field | Value |
|---|---|
| Assembly | BCM958802A8046C |
| Model | PS225-H16 |
| Revision | Rev 15 |
| Build Date | 2019-12-10 |
| Dev ID | DEV0000 |
| Expected DDR4 | 16GB |
| Status | Untested |

## Card 03

| Field | Value |
|---|---|
| Assembly | BCM958802A8028E |
| Model | PS225-H08 |
| Revision | Rev E |
| SoC | BCM58802H |
| Expected DDR4 | 8GB ECC, pending runtime verification |
| DRAM Marking | Micron D9TBK |
| Likely DRAM Part | MT40A512M16JY-083E:BFBGA |
| DRAM Packages | 10 total: 6 front, 4 rear |
| Status | Untested |

## Card 04

| Field | Value |
|---|---|
| Assembly | BCM958802A8028C |
| Model | PS225-H08 |
| Revision | Rev C |
| Build Date | 2021-12-27 |
| Dev ID | DEV0023 |
| Expected DDR4 | 8GB |
| Status | Untested |

## Console Cable

| Field | Value |
|---|---|
| Type | Official Broadcom USB-to-3.5mm TRRS serial console cable |
| Sticker | P/N 12233 / 0530 / 2201 |
| Status | Present |

## Next Bring-Up Tasks

1. Capture USB serial adapter enumeration from host.
2. Capture UART boot log from Card 01.
3. Capture `lspci -nnvv` for each card.
4. Confirm card memory sizes through bootloader or Linux.
5. Dump eMMC and SPI from known-good cards before modifying firmware.
